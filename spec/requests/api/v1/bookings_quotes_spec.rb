require 'rails_helper'

RSpec.describe 'Api::V1::Bookings - Quote Workflow', type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }
  let(:client) { create(:client, company: company) }
  let(:product) { create(:product, company: company, quantity: 10, daily_price_cents: 5000) }

  before do
    ActsAsTenant.current_tenant = company
  end

  describe 'Quote Conversion and Workflow' do
    let(:booking) do
      create(:booking, :draft,
        company: company,
        client: client,
        start_date: 10.days.from_now,
        end_date: 15.days.from_now
      )
    end

    let!(:line_item) { create(:booking_line_item, booking: booking, bookable: product) }

    context 'converting booking to quote' do
      it 'converts a draft booking to quote' do
        expect(booking.quote_number).to be_nil

        booking.convert_to_quote!(valid_days: 30, terms: 'Standard terms apply')

        expect(booking.reload.quote_number).to be_present
        expect(booking.quote_number).to match(/^QT\d{8}[A-F0-9]{8}$/)
        expect(booking.quote_status).to eq('quote_draft')
        expect(booking.quote_valid_days).to eq(30)
        expect(booking.quote_expires_at).to be_within(1.minute).of(30.days.from_now)
      end

      it 'does not convert if already has quote_number' do
        booking.convert_to_quote!
        original_quote_number = booking.quote_number

        result = booking.convert_to_quote!

        expect(result).to be false
        expect(booking.reload.quote_number).to eq(original_quote_number)
      end
    end

    context 'sending quote' do
      before do
        booking.convert_to_quote!(valid_days: 14)
      end

      it 'sends a quote' do
        expect(booking.quote_status).to eq('quote_draft')

        booking.send_quote!

        expect(booking.reload.quote_status).to eq('quote_sent')
        expect(booking.quote_sent_at).to be_present
        expect(booking.quote_sent_at).to be_within(1.minute).of(Time.current)
      end

      it 'does not send expired quote' do
        booking.update(quote_expires_at: 1.day.ago, quote_status: :quote_expired)

        result = booking.send_quote!

        expect(result).to be false
        expect(booking.reload.quote_status).to eq('quote_expired')
      end
    end

    context 'viewing quote' do
      before do
        booking.convert_to_quote!
        booking.send_quote!
      end

      it 'marks quote as viewed' do
        expect(booking.quote_status).to eq('quote_sent')

        booking.mark_quote_viewed!

        expect(booking.reload.quote_status).to eq('quote_viewed')
        expect(booking.quote_viewed_at).to be_present
      end

      it 'only marks viewed from sent status' do
        booking.update(quote_status: :quote_draft)

        result = booking.mark_quote_viewed!

        expect(result).to be false
      end
    end

    context 'approving quote' do
      before do
        booking.convert_to_quote!
        booking.send_quote!
      end

      it 'approves quote and converts to confirmed booking' do
        booking.approve_quote!(approved_by: user)

        expect(booking.reload.quote_status).to eq('quote_approved')
        expect(booking.quote_approved_at).to be_present
        expect(booking.quote_approved_by).to eq(user)
        expect(booking.status).to eq('confirmed')
        expect(booking.converted_from_quote).to be true
      end

      it 'does not approve expired quote' do
        booking.update(quote_expires_at: 1.day.ago)

        result = booking.approve_quote!(approved_by: user)

        expect(result).to be false
        expect(booking.reload.status).not_to eq('confirmed')
      end
    end

    context 'declining quote' do
      before do
        booking.convert_to_quote!
        booking.send_quote!
      end

      it 'declines quote with reason' do
        reason = 'Price too high'

        booking.decline_quote!(reason: reason)

        expect(booking.reload.quote_status).to eq('quote_declined')
        expect(booking.quote_declined_at).to be_present
        expect(booking.quote_decline_reason).to eq(reason)
      end
    end

    context 'quote expiration' do
      it 'identifies expired quotes' do
        booking.convert_to_quote!(valid_days: -1)

        expect(booking.quote_expired?).to be true
      end

      it 'identifies non-expired quotes' do
        booking.convert_to_quote!(valid_days: 30)

        expect(booking.quote_expired?).to be false
      end

      it 'calculates days until expiry' do
        booking.convert_to_quote!(valid_days: 7)

        expect(booking.days_until_expiry).to be_within(1).of(7)
      end

      it 'detects quotes expiring soon' do
        booking.convert_to_quote!(valid_days: 2)

        expect(booking.quote_expiring_soon?(3)).to be true
        expect(booking.quote_expiring_soon?(1)).to be false
      end

      it 'batch expires old quotes' do
        # Create expired quotes
        expired_quote1 = create(:booking, company: company)
        expired_quote1.convert_to_quote!(valid_days: -1)
        expired_quote1.send_quote!

        expired_quote2 = create(:booking, company: company)
        expired_quote2.convert_to_quote!(valid_days: -2)
        expired_quote2.send_quote!

        Booking.expire_old_quotes!

        expect(expired_quote1.reload.quote_status).to eq('quote_expired')
        expect(expired_quote2.reload.quote_status).to eq('quote_expired')
      end
    end

    context 'duplicating quote' do
      before do
        booking.convert_to_quote!(valid_days: 30)
      end

      it 'creates a duplicate quote with new numbers' do
        duplicate = booking.duplicate_quote(customer_name: 'Updated Customer')

        expect(duplicate).to be_persisted
        expect(duplicate.id).not_to eq(booking.id)
        expect(duplicate.quote_number).not_to eq(booking.quote_number)
        expect(duplicate.reference_number).not_to eq(booking.reference_number)
        expect(duplicate.quote_status).to eq('quote_draft')
        expect(duplicate.customer_name).to eq('Updated Customer')
      end

      it 'duplicates line items' do
        duplicate = booking.duplicate_quote

        expect(duplicate.booking_line_items.count).to eq(booking.booking_line_items.count)
        expect(duplicate.booking_line_items.first.bookable).to eq(product)
      end

      it 'resets quote timestamps' do
        booking.send_quote!
        booking.mark_quote_viewed!

        duplicate = booking.duplicate_quote

        expect(duplicate.quote_sent_at).to be_nil
        expect(duplicate.quote_viewed_at).to be_nil
        expect(duplicate.quote_approved_at).to be_nil
      end

      it 'allows custom valid_days' do
        duplicate = booking.duplicate_quote(valid_days: 45)

        expect(duplicate.quote_expires_at).to be_within(1.hour).of(45.days.from_now)
      end
    end

    context 'quote scopes' do
      let!(:draft_quote) do
        b = create(:booking, :draft, company: company)
        b.convert_to_quote!
        b
      end

      let!(:sent_quote) do
        b = create(:booking, :draft, company: company)
        b.convert_to_quote!
        b.send_quote!
        b
      end

      let!(:expired_quote) do
        b = create(:booking, :draft, company: company)
        b.convert_to_quote!(valid_days: -1)
        b
      end

      it 'finds all quotes' do
        quotes = Booking.quotes

        expect(quotes).to include(draft_quote, sent_quote, expired_quote)
        expect(quotes).not_to include(booking) # Not converted to quote yet
      end

      it 'finds active quotes' do
        active = Booking.active_quotes

        expect(active).to include(draft_quote, sent_quote)
        expect(active).not_to include(expired_quote)
      end

      it 'finds expired quotes' do
        expired = Booking.expired_quotes

        expect(expired).to include(expired_quote)
        expect(expired).not_to include(draft_quote, sent_quote)
      end

      it 'finds pending quotes' do
        pending = Booking.pending_quotes

        expect(pending).to include(sent_quote)
        expect(pending).not_to include(draft_quote)
      end
    end
  end
end
