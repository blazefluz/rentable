# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendEmailCampaignJob, type: :job do
  let(:company) { create(:company) }
  let(:email_campaign) { create(:email_campaign, :active, company: company) }

  describe '#perform' do
    context 'with quote_followup campaign' do
      let(:campaign) do
        create(:email_campaign,
               :quote_followup,
               :active,
               :with_sequences,
               company: company)
      end
      let(:booking) do
        create(:booking,
               company: company,
               quote_status: 'pending_quotes',
               customer_email: 'customer@example.com')
      end

      it 'schedules emails for the first sequence' do
        ActsAsTenant.with_tenant(company) do
          expect {
            described_class.perform_now(campaign.id, booking.id)
          }.to change(EmailQueue, :count).by(1)
        end
      end

      it 'uses correct recipient email' do
        ActsAsTenant.with_tenant(company) do
          described_class.perform_now(campaign.id, booking.id)

          email = EmailQueue.last
          expect(email.recipient).to eq('customer@example.com')
        end
      end

      it 'substitutes variables in email content' do
        ActsAsTenant.with_tenant(company) do
          campaign.email_sequences.first.update!(
            subject_template: 'Quote {{quote_number}} for {{customer_name}}'
          )

          described_class.perform_now(campaign.id, booking.id)

          email = EmailQueue.last
          expect(email.subject).to include(booking.reference_number)
          expect(email.subject).to include(booking.customer_name)
        end
      end

      it 'schedules email based on sequence delay' do
        ActsAsTenant.with_tenant(company) do
          sequence = campaign.email_sequences.first
          sequence.update!(send_delay_hours: 72)

          described_class.perform_now(campaign.id, booking.id)

          email = EmailQueue.last
          expected_time = Time.current + 72.hours

          expect(email.scheduled_at).to be_within(1.minute).of(expected_time)
        end
      end

      it 'does not send when campaign cannot send' do
        ActsAsTenant.with_tenant(company) do
          campaign.update!(status: :paused)

          expect {
            described_class.perform_now(campaign.id, booking.id)
          }.not_to change(EmailQueue, :count)
        end
      end
    end

    context 'with customer_reengagement campaign' do
      let(:campaign) do
        create(:email_campaign,
               :customer_reengagement,
               :active,
               :with_sequences,
               company: company)
      end
      let(:segment) do
        create(:client_segment,
               :dormant,
               company: company)
      end
      let!(:dormant_clients) do
        ActsAsTenant.with_tenant(company) do
          create_list(:client, 3,
                      company: company,
                      last_rental_date: 120.days.ago)
        end
      end

      before do
        campaign.update!(trigger_conditions: { client_segment_id: segment.id })
      end

      it 'sends to all clients in segment' do
        ActsAsTenant.with_tenant(company) do
          expect {
            described_class.perform_now(campaign.id)
          }.to change(EmailQueue, :count).by(3)
        end
      end

      it 'uses correct client email addresses' do
        ActsAsTenant.with_tenant(company) do
          described_class.perform_now(campaign.id)

          emails = EmailQueue.last(3)
          recipients = emails.map(&:recipient)

          dormant_clients.each do |client|
            expect(recipients).to include(client.email)
          end
        end
      end
    end

    context 'with multiple sequences' do
      let(:campaign) do
        create(:email_campaign,
               :quote_followup,
               :active,
               company: company)
      end
      let(:booking) do
        create(:booking,
               company: company,
               quote_status: 'pending_quotes',
               customer_email: 'customer@example.com')
      end

      before do
        ActsAsTenant.with_tenant(company) do
          create(:email_sequence, :day_three, email_campaign: campaign)
          create(:email_sequence, :day_seven, email_campaign: campaign)
        end
      end

      it 'schedules all sequences' do
        ActsAsTenant.with_tenant(company) do
          expect {
            described_class.perform_now(campaign.id, booking.id)
          }.to change(EmailQueue, :count).by(2)
        end
      end

      it 'schedules sequences with correct delays' do
        ActsAsTenant.with_tenant(company) do
          described_class.perform_now(campaign.id, booking.id)

          emails = EmailQueue.last(2)
          day_3_email = emails.find { |e| e.scheduled_at <= 3.days.from_now + 1.hour }
          day_7_email = emails.find { |e| e.scheduled_at >= 7.days.from_now - 1.hour }

          expect(day_3_email).to be_present
          expect(day_7_email).to be_present
        end
      end
    end

    context 'error handling' do
      it 'handles missing campaign gracefully' do
        expect {
          described_class.perform_now(999999, nil)
        }.not_to raise_error
      end

      it 'handles missing booking for quote campaigns' do
        ActsAsTenant.with_tenant(company) do
          campaign = create(:email_campaign, :quote_followup, :active, company: company)

          expect {
            described_class.perform_now(campaign.id, 999999)
          }.not_to raise_error
        end
      end
    end
  end
end
