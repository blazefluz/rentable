require 'rails_helper'

RSpec.describe 'Api::V1::Bookings - Accounts Receivable & Collections', type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }
  let(:client) { create(:client, company: company, payment_terms_days: 30) }

  before do
    ActsAsTenant.current_tenant = company
  end

  describe 'Payment Due Date Management' do
    let(:booking) do
      create(:booking,
        company: company,
        client: client,
        start_date: 5.days.ago,
        end_date: 2.days.ago,
        total_price_cents: 100000,
        status: :completed
      )
    end

    context 'payment due date calculation' do
      it 'calculates due date based on client payment terms' do
        due_date = booking.calculate_payment_due_date

        expect(due_date).to eq(booking.end_date + 30.days)
      end

      it 'uses default 30 days when client has no payment terms' do
        booking.client.update(payment_terms_days: nil)
        due_date = booking.calculate_payment_due_date

        expect(due_date).to eq(booking.end_date + 30.days)
      end

      it 'sets payment due date automatically' do
        booking.set_payment_due_date!

        expect(booking.reload.payment_due_date).to be_present
        expect(booking.payment_due_date).to eq(booking.end_date + 30.days)
      end

      it 'does not override existing payment due date' do
        existing_date = 15.days.from_now
        booking.update(payment_due_date: existing_date)

        booking.set_payment_due_date!

        expect(booking.reload.payment_due_date).to eq(existing_date)
      end
    end

    context 'days past due calculation' do
      it 'calculates days past due correctly' do
        booking.update(payment_due_date: 10.days.ago)

        days_past = booking.calculate_days_past_due

        expect(days_past).to eq(10)
      end

      it 'returns 0 when payment not yet due' do
        booking.update(payment_due_date: 10.days.from_now)

        expect(booking.calculate_days_past_due).to eq(0)
      end

      it 'returns 0 when fully paid' do
        booking.update(payment_due_date: 10.days.ago)
        create(:payment,
          booking: booking,
          payment_type: :payment_received,
          amount_cents: 100000
        )

        expect(booking.calculate_days_past_due).to eq(0)
      end

      it 'updates days_past_due field' do
        booking.update(payment_due_date: 15.days.ago)

        booking.update_days_past_due!

        expect(booking.reload.days_past_due).to eq(15)
      end
    end

    context 'overdue status check' do
      it 'identifies overdue bookings' do
        booking.update(payment_due_date: 5.days.ago)

        expect(booking.payment_overdue?).to be true
      end

      it 'does not mark future due dates as overdue' do
        booking.update(payment_due_date: 5.days.from_now)

        expect(booking.payment_overdue?).to be false
      end

      it 'does not mark fully paid bookings as overdue' do
        booking.update(payment_due_date: 5.days.ago)
        create(:payment,
          booking: booking,
          payment_type: :payment_received,
          amount_cents: 100000
        )

        expect(booking.payment_overdue?).to be false
      end
    end
  end

  describe 'Aging Bucket Management' do
    let(:booking) do
      create(:booking,
        company: company,
        total_price_cents: 100000,
        payment_due_date: nil
      )
    end

    context 'aging bucket calculation' do
      it 'assigns current bucket when not past due' do
        booking.update(payment_due_date: 5.days.from_now)

        bucket = booking.calculate_aging_bucket

        expect(bucket).to eq(:current)
      end

      it 'assigns 0-30 bucket for 1-30 days past due' do
        booking.update(payment_due_date: 15.days.ago, days_past_due: 15)

        bucket = booking.calculate_aging_bucket

        expect(bucket).to eq(:days_0_30)
      end

      it 'assigns 31-60 bucket for 31-60 days past due' do
        booking.update(payment_due_date: 45.days.ago, days_past_due: 45)

        bucket = booking.calculate_aging_bucket

        expect(bucket).to eq(:days_31_60)
      end

      it 'assigns 61-90 bucket for 61-90 days past due' do
        booking.update(payment_due_date: 75.days.ago, days_past_due: 75)

        bucket = booking.calculate_aging_bucket

        expect(bucket).to eq(:days_61_90)
      end

      it 'assigns 90+ bucket for over 90 days past due' do
        booking.update(payment_due_date: 100.days.ago, days_past_due: 100)

        bucket = booking.calculate_aging_bucket

        expect(bucket).to eq(:days_90_plus)
      end

      it 'assigns current bucket when fully paid' do
        booking.update(payment_due_date: 30.days.ago)
        create(:payment,
          booking: booking,
          payment_type: :payment_received,
          amount_cents: 100000
        )

        bucket = booking.calculate_aging_bucket

        expect(bucket).to eq(:current)
      end
    end

    context 'aging bucket update' do
      it 'updates aging_bucket field' do
        booking.update(payment_due_date: 45.days.ago, days_past_due: 45)

        booking.update_aging_bucket!

        expect(booking.reload.aging_bucket).to eq('days_31_60')
      end
    end

    context 'AR metrics update' do
      it 'updates all AR metrics at once' do
        booking.update(
          end_date: 40.days.ago,
          payment_due_date: nil
        )

        booking.update_ar_metrics!

        booking.reload
        expect(booking.payment_due_date).to be_present
        expect(booking.days_past_due).to be > 0
        expect(booking.aging_bucket).to eq('days_0_30')
      end
    end
  end

  describe 'Collection Rate and Expected Recovery' do
    let(:booking) do
      create(:booking,
        company: company,
        total_price_cents: 100000,
        payment_due_date: nil
      )
    end

    context 'expected collection rate' do
      it 'returns 100% for current accounts' do
        booking.update(aging_bucket: :current)

        expect(booking.expected_collection_rate).to eq(1.0)
      end

      it 'returns 90% for 0-30 days past due' do
        booking.update(aging_bucket: :days_0_30)

        expect(booking.expected_collection_rate).to eq(0.90)
      end

      it 'returns 75% for 31-60 days past due' do
        booking.update(aging_bucket: :days_31_60)

        expect(booking.expected_collection_rate).to eq(0.75)
      end

      it 'returns 60% for 61-90 days past due' do
        booking.update(aging_bucket: :days_61_90)

        expect(booking.expected_collection_rate).to eq(0.60)
      end

      it 'returns 25% for 90+ days past due' do
        booking.update(aging_bucket: :days_90_plus)

        expect(booking.expected_collection_rate).to eq(0.25)
      end
    end

    context 'expected collectible amount' do
      it 'calculates collectible amount based on aging' do
        booking.update(aging_bucket: :days_31_60)
        # Balance due: $1,000
        # Expected rate: 75%
        # Expected collectible: $750

        collectible = booking.expected_collectible_amount

        expect(collectible.cents).to eq(75000)
      end

      it 'adjusts for partial payments' do
        booking.update(aging_bucket: :days_0_30)
        create(:payment,
          booking: booking,
          payment_type: :payment_received,
          amount_cents: 30000
        )

        collectible = booking.expected_collectible_amount
        # Balance due: $700
        # Expected rate: 90%
        # Expected collectible: $630

        expect(collectible.cents).to eq(63000)
      end
    end
  end

  describe 'Collection Status Escalation' do
    let(:booking) do
      create(:booking,
        company: company,
        total_price_cents: 100000,
        payment_due_date: 50.days.ago,
        days_past_due: 50,
        collection_status: :current_status,
        payment_reminder_count: 0
      )
    end

    context 'automatic escalation' do
      it 'escalates to reminder_sent at 7-13 days' do
        booking.update(days_past_due: 10)

        booking.escalate_collection_status!

        expect(booking.reload.collection_status).to eq('reminder_sent')
      end

      it 'escalates to first_notice at 14-29 days' do
        booking.update(days_past_due: 20, collection_status: :reminder_sent)

        booking.escalate_collection_status!

        expect(booking.reload.collection_status).to eq('first_notice')
      end

      it 'escalates to second_notice at 30-59 days' do
        booking.update(days_past_due: 40, collection_status: :first_notice)

        booking.escalate_collection_status!

        expect(booking.reload.collection_status).to eq('second_notice')
      end

      it 'escalates to final_notice at 60-89 days' do
        booking.update(days_past_due: 70, collection_status: :second_notice)

        booking.escalate_collection_status!

        expect(booking.reload.collection_status).to eq('final_notice')
      end

      it 'escalates to in_collections at 90+ days' do
        booking.update(days_past_due: 95, collection_status: :final_notice)

        booking.escalate_collection_status!

        expect(booking.reload.collection_status).to eq('in_collections')
      end

      it 'does not escalate fully paid bookings' do
        create(:payment,
          booking: booking,
          payment_type: :payment_received,
          amount_cents: 100000
        )

        booking.escalate_collection_status!

        # Should remain at current status
        expect(booking.reload.collection_status).to eq('current_status')
      end
    end
  end

  describe 'Payment Reminders' do
    let(:booking) do
      create(:booking,
        company: company,
        total_price_cents: 100000,
        payment_due_date: 10.days.ago,
        payment_reminder_count: 0,
        last_payment_reminder_sent_at: nil
      )
    end

    context 'sending payment reminders' do
      it 'sends payment reminder and tracks it' do
        booking.send_payment_reminder!(reminder_type: :friendly)

        booking.reload
        expect(booking.last_payment_reminder_sent_at).to be_present
        expect(booking.last_payment_reminder_sent_at).to be_within(1.minute).of(Time.current)
        expect(booking.payment_reminder_count).to eq(1)
      end

      it 'increments reminder count on subsequent reminders' do
        booking.send_payment_reminder!
        booking.send_payment_reminder!

        expect(booking.reload.payment_reminder_count).to eq(2)
      end

      it 'does not send reminder for fully paid bookings' do
        create(:payment,
          booking: booking,
          payment_type: :payment_received,
          amount_cents: 100000
        )

        booking.send_payment_reminder!

        expect(booking.reload.payment_reminder_count).to eq(0)
      end

      it 'escalates collection status after reminder' do
        booking.update(days_past_due: 10, collection_status: :current_status)

        booking.send_payment_reminder!

        expect(booking.reload.collection_status).to eq('reminder_sent')
      end
    end
  end

  describe 'Collections Assignment and Write-offs' do
    let(:booking) do
      create(:booking,
        company: company,
        total_price_cents: 100000,
        payment_due_date: 95.days.ago,
        days_past_due: 95
      )
    end

    context 'assigning to collections' do
      it 'assigns booking to collections user' do
        booking.assign_to_collections!(
          user,
          notes: 'Unresponsive to reminders'
        )

        booking.reload
        expect(booking.collection_status).to eq('in_collections')
        expect(booking.collection_assigned_to).to eq(user)
        expect(booking.collection_notes).to eq('Unresponsive to reminders')
      end
    end

    context 'writing off bad debt' do
      it 'writes off booking as bad debt' do
        booking.write_off_bad_debt!(
          reason: 'Company went bankrupt',
          user: user
        )

        booking.reload
        expect(booking.collection_status).to eq('written_off')
        expect(booking.collection_notes).to include('Company went bankrupt')
        expect(booking.collection_notes).to include(user.email)
      end

      it 'includes balance in write-off notes' do
        booking.write_off_bad_debt!(reason: 'Test', user: user)

        expect(booking.collection_notes).to include('$1,000.00')
      end
    end
  end

  describe 'AR Aging Summary Report' do
    before do
      # Create bookings in different aging buckets
      create(:booking,
        company: company,
        total_price_cents: 50000,
        payment_due_date: 5.days.from_now,
        days_past_due: 0,
        aging_bucket: :current
      )

      create(:booking,
        company: company,
        total_price_cents: 30000,
        payment_due_date: 15.days.ago,
        days_past_due: 15,
        aging_bucket: :days_0_30
      )

      create(:booking,
        company: company,
        total_price_cents: 20000,
        payment_due_date: 45.days.ago,
        days_past_due: 45,
        aging_bucket: :days_31_60
      )
    end

    it 'generates AR aging summary' do
      summary = Booking.ar_aging_summary(currency: 'USD')

      expect(summary).to have_key(:current)
      expect(summary).to have_key(:days_0_30)
      expect(summary).to have_key(:days_31_60)
      expect(summary).to have_key(:days_61_90)
      expect(summary).to have_key(:days_90_plus)
      expect(summary).to have_key(:total)
    end

    it 'includes count and balance for each bucket' do
      summary = Booking.ar_aging_summary(currency: 'USD')

      expect(summary[:current][:count]).to eq(1)
      expect(summary[:current][:balance].cents).to eq(50000)

      expect(summary[:days_0_30][:count]).to eq(1)
      expect(summary[:days_0_30][:balance].cents).to eq(30000)
    end

    it 'calculates total AR correctly' do
      summary = Booking.ar_aging_summary(currency: 'USD')

      expect(summary[:total][:count]).to eq(3)
      expect(summary[:total][:balance].cents).to eq(100000)
    end
  end

  describe 'AR Scopes' do
    let!(:current_booking) do
      create(:booking,
        company: company,
        total_price_cents: 10000,
        payment_due_date: 5.days.from_now,
        aging_bucket: :current
      )
    end

    let!(:overdue_booking) do
      create(:booking,
        company: company,
        total_price_cents: 20000,
        payment_due_date: 10.days.ago,
        aging_bucket: :days_0_30
      )
    end

    let!(:paid_booking) do
      b = create(:booking,
        company: company,
        total_price_cents: 15000,
        payment_due_date: 5.days.ago
      )
      create(:payment,
        booking: b,
        payment_type: :payment_received,
        amount_cents: 15000
      )
      b
    end

    context 'with_balance_due scope' do
      it 'returns bookings with outstanding balance' do
        results = Booking.with_balance_due

        expect(results).to include(current_booking, overdue_booking)
        expect(results).not_to include(paid_booking)
      end
    end

    context 'overdue scope' do
      it 'returns only overdue bookings' do
        results = Booking.overdue

        expect(results).to include(overdue_booking)
        expect(results).not_to include(current_booking, paid_booking)
      end
    end

    context 'aging bucket scopes' do
      it 'filters by current bucket' do
        results = Booking.current_ar

        expect(results).to include(current_booking)
      end

      it 'filters by 0-30 days bucket' do
        results = Booking.aged_0_30

        expect(results).to include(overdue_booking)
      end
    end

    context 'needs_reminder scope' do
      it 'finds bookings needing payment reminder' do
        overdue_booking.update(
          last_payment_reminder_sent_at: nil,
          payment_due_date: 10.days.ago
        )

        results = Booking.needs_reminder

        expect(results).to include(overdue_booking)
      end

      it 'excludes recently reminded bookings' do
        overdue_booking.update(
          last_payment_reminder_sent_at: 2.days.ago,
          payment_due_date: 10.days.ago
        )

        results = Booking.needs_reminder

        expect(results).not_to include(overdue_booking)
      end
    end

    context 'in_collections_status scope' do
      let!(:collections_booking) do
        create(:booking,
          company: company,
          collection_status: :in_collections
        )
      end

      it 'finds bookings in collections' do
        results = Booking.in_collections_status

        expect(results).to include(collections_booking)
      end
    end
  end
end
