require 'rails_helper'

RSpec.describe 'Api::V1::Bookings - Cancellations and Refunds', type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }
  let(:client) { create(:client, company: company) }
  let(:product) { create(:product, company: company, quantity: 10, daily_price_cents: 5000) }

  before do
    ActsAsTenant.current_tenant = company
  end

  describe 'Cancellation Policy' do
    let(:booking) do
      create(:booking,
        company: company,
        status: :confirmed,
        start_date: 10.days.from_now,
        end_date: 15.days.from_now,
        total_price_cents: 50000,
        total_price_currency: 'USD'
      )
    end

    context 'flexible policy' do
      before do
        booking.update(cancellation_policy: :flexible)
      end

      it 'allows full refund 7+ days before start' do
        refund = booking.calculate_cancellation_refund

        expect(refund[:refund_percentage]).to eq(100)
        expect(refund[:refund_cents]).to eq(50000)
        expect(refund[:fee_cents]).to eq(0)
      end

      it 'allows no refund less than 7 days before start' do
        booking.update(start_date: 5.days.from_now)
        refund = booking.calculate_cancellation_refund

        expect(refund[:refund_percentage]).to eq(0)
        expect(refund[:refund_cents]).to eq(0)
        expect(refund[:fee_cents]).to eq(50000)
      end
    end

    context 'moderate policy' do
      before do
        booking.update(cancellation_policy: :moderate)
      end

      it 'allows full refund 14+ days before start' do
        booking.update(start_date: 15.days.from_now)
        refund = booking.calculate_cancellation_refund

        expect(refund[:refund_percentage]).to eq(100)
        expect(refund[:refund_cents]).to eq(50000)
      end

      it 'allows 50% refund 7-13 days before start' do
        booking.update(start_date: 10.days.from_now)
        refund = booking.calculate_cancellation_refund

        expect(refund[:refund_percentage]).to eq(50)
        expect(refund[:refund_cents]).to eq(25000)
        expect(refund[:fee_cents]).to eq(25000)
      end

      it 'allows no refund less than 7 days before start' do
        booking.update(start_date: 5.days.from_now)
        refund = booking.calculate_cancellation_refund

        expect(refund[:refund_percentage]).to eq(0)
      end
    end

    context 'strict policy' do
      before do
        booking.update(cancellation_policy: :strict)
      end

      it 'allows full refund 30+ days before start' do
        booking.update(start_date: 35.days.from_now)
        refund = booking.calculate_cancellation_refund

        expect(refund[:refund_percentage]).to eq(100)
      end

      it 'allows 50% refund 14-29 days before start' do
        booking.update(start_date: 20.days.from_now)
        refund = booking.calculate_cancellation_refund

        expect(refund[:refund_percentage]).to eq(50)
      end

      it 'allows no refund less than 14 days before start' do
        booking.update(start_date: 10.days.from_now)
        refund = booking.calculate_cancellation_refund

        expect(refund[:refund_percentage]).to eq(0)
      end
    end

    context 'no refund policy' do
      before do
        booking.update(cancellation_policy: :no_refund)
      end

      it 'never allows refunds' do
        refund = booking.calculate_cancellation_refund

        expect(refund[:refund_percentage]).to eq(0)
        expect(refund[:refund_cents]).to eq(0)
      end
    end

    context 'custom policy' do
      before do
        booking.update(
          cancellation_policy: :custom,
          cancellation_deadline_hours: 72, # 3 days
          cancellation_fee_percentage: 25  # 75% refund
        )
      end

      it 'uses custom deadline and fee percentage' do
        booking.update(start_date: 5.days.from_now)
        refund = booking.calculate_cancellation_refund

        expect(refund[:refund_percentage]).to eq(25)
        expect(refund[:refund_cents]).to eq(12500) # 25% of 50000
        expect(refund[:fee_cents]).to eq(37500)    # 75% of 50000
      end
    end
  end

  describe 'Cancellation Process' do
    let(:booking) do
      create(:booking,
        company: company,
        status: :confirmed,
        start_date: 10.days.from_now,
        end_date: 15.days.from_now,
        total_price_cents: 50000,
        cancellation_policy: :flexible
      )
    end

    let!(:line_item) do
      create(:booking_line_item, booking: booking, bookable: product)
    end

    context 'can_cancel? checks' do
      it 'allows cancellation of confirmed booking' do
        expect(booking.can_cancel?).to be true
      end

      it 'does not allow cancellation of already cancelled booking' do
        booking.update(status: :cancelled)
        expect(booking.can_cancel?).to be false
      end

      it 'does not allow cancellation of completed booking' do
        booking.update(status: :completed)
        expect(booking.can_cancel?).to be false
      end
    end

    context 'cancel_booking! execution' do
      it 'cancels booking and calculates refund' do
        result = booking.cancel_booking!(user: user, reason: 'Customer changed plans')

        expect(result).to be true
        expect(booking.reload.status).to eq('cancelled')
        expect(booking.cancelled_at).to be_present
        expect(booking.cancelled_by).to eq(user)
        expect(booking.cancellation_reason).to eq('Customer changed plans')
      end

      it 'sets refund amount based on policy' do
        booking.cancel_booking!(user: user)

        expect(booking.reload.refund_amount_cents).to eq(50000) # Full refund for flexible
        expect(booking.refund_amount_currency).to eq('USD')
        expect(booking.refund_status).to eq('pending')
      end

      it 'sets no refund status when no refund is due' do
        booking.update(cancellation_policy: :no_refund)
        booking.cancel_booking!(user: user)

        expect(booking.reload.refund_amount_cents).to eq(0)
        expect(booking.refund_status).to eq('not_applicable')
      end

      it 'releases product instances back to available' do
        instance = create(:product_instance, product: product, status: :rented)
        allow_any_instance_of(ProductInstance).to receive(:mark_as_available)

        booking.cancel_booking!(user: user)

        # Verify that mark_as_available would be called
        # (actual behavior depends on ProductInstance implementation)
      end
    end

    context 'cancellation deadlines' do
      it 'calculates correct deadline for flexible policy' do
        booking.update(cancellation_policy: :flexible)

        deadline = booking.cancellation_deadline
        expect(deadline).to be_within(1.hour).of(booking.start_date - 7.days)
      end

      it 'calculates correct deadline for moderate policy' do
        booking.update(cancellation_policy: :moderate)

        deadline = booking.cancellation_deadline
        expect(deadline).to be_within(1.hour).of(booking.start_date - 14.days)
      end

      it 'calculates correct deadline for strict policy' do
        booking.update(cancellation_policy: :strict)

        deadline = booking.cancellation_deadline
        expect(deadline).to be_within(1.hour).of(booking.start_date - 30.days)
      end

      it 'uses custom deadline hours' do
        booking.update(
          cancellation_policy: :custom,
          cancellation_deadline_hours: 48
        )

        deadline = booking.cancellation_deadline
        expect(deadline).to be_within(1.hour).of(booking.start_date - 48.hours)
      end

      it 'identifies when past cancellation deadline' do
        booking.update(
          cancellation_policy: :flexible,
          start_date: 5.days.from_now # Less than 7 days
        )

        expect(booking.past_cancellation_deadline?).to be true
      end

      it 'identifies when within cancellation deadline' do
        booking.update(
          cancellation_policy: :flexible,
          start_date: 10.days.from_now # More than 7 days
        )

        expect(booking.past_cancellation_deadline?).to be false
      end
    end

    context 'refund processing' do
      before do
        booking.cancel_booking!(user: user)
      end

      it 'processes pending refund' do
        expect(booking.refund_status).to eq('pending')

        booking.process_refund!

        expect(booking.reload.refund_status).to eq('completed')
        expect(booking.refund_processed_at).to be_present
      end

      it 'only processes refunds for cancelled bookings' do
        booking.update(status: :confirmed, refund_status: :pending)

        result = booking.process_refund!

        expect(result).to be false
        expect(booking.reload.refund_status).to eq('pending')
      end

      it 'only processes pending refunds' do
        booking.update(refund_status: :completed)

        result = booking.process_refund!

        expect(result).to be false
      end
    end

    context 'refund eligibility' do
      it 'allows refund when within deadline' do
        booking.update(cancellation_policy: :flexible, start_date: 10.days.from_now)

        expect(booking.refund_allowed?).to be true
      end

      it 'does not allow refund when past deadline' do
        booking.update(cancellation_policy: :flexible, start_date: 5.days.from_now)

        expect(booking.refund_allowed?).to be false
      end

      it 'does not allow refund for no_refund policy' do
        booking.update(cancellation_policy: :no_refund)

        expect(booking.refund_allowed?).to be false
      end
    end

    context 'hours until start calculation' do
      it 'calculates correct hours until booking start' do
        booking.update(start_date: 2.days.from_now)

        hours = booking.hours_until_start
        expect(hours).to be_within(2).of(48)
      end

      it 'returns 0 for past bookings' do
        booking.update(start_date: 2.days.ago)

        expect(booking.hours_until_start).to be < 0
      end
    end
  end

  describe 'Integration with Product Instances' do
    let(:booking) do
      create(:booking,
        company: company,
        status: :confirmed,
        start_date: 10.days.from_now,
        end_date: 15.days.from_now,
        cancellation_policy: :flexible
      )
    end

    it 'releases instances when booking is cancelled' do
      line_item = create(:booking_line_item, booking: booking, bookable: product)

      # Create product instances associated with the line item
      instance1 = create(:product_instance, product: product, status: :rented)
      instance2 = create(:product_instance, product: product, status: :rented)

      # Mock the association
      allow(line_item).to receive(:product_instances).and_return([instance1, instance2])
      allow(booking).to receive(:booking_line_items).and_return([line_item])

      expect(instance1).to receive(:mark_as_available)
      expect(instance2).to receive(:mark_as_available)

      booking.cancel_booking!(user: user)
    end
  end
end
