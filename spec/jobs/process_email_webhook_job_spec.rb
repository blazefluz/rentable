# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProcessEmailWebhookJob, type: :job do
  let(:company) { create(:company) }

  describe '#perform' do
    context 'with delivered event' do
      let(:event_data) do
        {
          'event' => 'delivered',
          'email' => 'customer@example.com',
          'sg_message_id' => 'msg-123',
          'timestamp' => Time.current.to_i
        }
      end

      let!(:email_queue) do
        ActsAsTenant.with_tenant(company) do
          create(:email_queue,
                 :sent,
                 company: company,
                 recipient: 'customer@example.com',
                 metadata: { sendgrid_message_id: 'msg-123' })
        end
      end

      it 'updates email queue delivered_at' do
        ActsAsTenant.with_tenant(company) do
          described_class.perform_now(event_data)

          expect(email_queue.reload.delivered_at).to be_present
        end
      end

      it 'sets delivered_at to event timestamp' do
        ActsAsTenant.with_tenant(company) do
          described_class.perform_now(event_data)

          expected_time = Time.at(event_data['timestamp'])
          expect(email_queue.reload.delivered_at).to be_within(1.second).of(expected_time)
        end
      end
    end

    context 'with open event' do
      let(:event_data) do
        {
          'event' => 'open',
          'email' => 'customer@example.com',
          'sg_message_id' => 'msg-456',
          'timestamp' => Time.current.to_i
        }
      end

      let!(:email_queue) do
        ActsAsTenant.with_tenant(company) do
          create(:email_queue,
                 :delivered,
                 company: company,
                 recipient: 'customer@example.com',
                 metadata: { sendgrid_message_id: 'msg-456' })
        end
      end

      it 'updates email queue opened_at' do
        ActsAsTenant.with_tenant(company) do
          described_class.perform_now(event_data)

          expect(email_queue.reload.opened_at).to be_present
        end
      end

      it 'only updates first open (not subsequent opens)' do
        ActsAsTenant.with_tenant(company) do
          # First open
          described_class.perform_now(event_data)
          first_opened_at = email_queue.reload.opened_at

          # Second open (1 hour later)
          later_event = event_data.merge('timestamp' => 1.hour.from_now.to_i)
          described_class.perform_now(later_event)

          # Should still be the first open time
          expect(email_queue.reload.opened_at).to be_within(1.second).of(first_opened_at)
        end
      end
    end

    context 'with click event' do
      let(:event_data) do
        {
          'event' => 'click',
          'email' => 'customer@example.com',
          'sg_message_id' => 'msg-789',
          'timestamp' => Time.current.to_i,
          'url' => 'https://example.com/booking/123'
        }
      end

      let!(:email_queue) do
        ActsAsTenant.with_tenant(company) do
          create(:email_queue,
                 :opened,
                 company: company,
                 recipient: 'customer@example.com',
                 metadata: { sendgrid_message_id: 'msg-789' })
        end
      end

      it 'updates email queue clicked_at' do
        ActsAsTenant.with_tenant(company) do
          described_class.perform_now(event_data)

          expect(email_queue.reload.clicked_at).to be_present
        end
      end

      it 'stores clicked URL in metadata' do
        ActsAsTenant.with_tenant(company) do
          described_class.perform_now(event_data)

          expect(email_queue.reload.metadata['clicked_url']).to eq('https://example.com/booking/123')
        end
      end
    end

    context 'with bounce event' do
      let(:event_data) do
        {
          'event' => 'bounce',
          'email' => 'invalid@example.com',
          'sg_message_id' => 'msg-bounce',
          'timestamp' => Time.current.to_i,
          'reason' => 'Email address does not exist'
        }
      end

      let!(:email_queue) do
        ActsAsTenant.with_tenant(company) do
          create(:email_queue,
                 :sent,
                 company: company,
                 recipient: 'invalid@example.com',
                 metadata: { sendgrid_message_id: 'msg-bounce' })
        end
      end

      it 'updates email queue bounced_at' do
        ActsAsTenant.with_tenant(company) do
          described_class.perform_now(event_data)

          expect(email_queue.reload.bounced_at).to be_present
        end
      end

      it 'stores bounce reason' do
        ActsAsTenant.with_tenant(company) do
          described_class.perform_now(event_data)

          expect(email_queue.reload.bounce_reason).to eq('Email address does not exist')
        end
      end

      it 'updates status to failed' do
        ActsAsTenant.with_tenant(company) do
          described_class.perform_now(event_data)

          expect(email_queue.reload.status).to eq('failed')
        end
      end
    end

    context 'with unsubscribe event' do
      let(:event_data) do
        {
          'event' => 'unsubscribe',
          'email' => 'unsubscribe@example.com',
          'sg_message_id' => 'msg-unsub',
          'timestamp' => Time.current.to_i
        }
      end

      let!(:email_queue) do
        ActsAsTenant.with_tenant(company) do
          create(:email_queue,
                 :delivered,
                 company: company,
                 recipient: 'unsubscribe@example.com',
                 metadata: { sendgrid_message_id: 'msg-unsub' })
        end
      end

      it 'updates email queue unsubscribed_at' do
        ActsAsTenant.with_tenant(company) do
          described_class.perform_now(event_data)

          expect(email_queue.reload.unsubscribed_at).to be_present
        end
      end

      it 'marks email as unsubscribed in metadata' do
        ActsAsTenant.with_tenant(company) do
          described_class.perform_now(event_data)

          expect(email_queue.reload.metadata['unsubscribed']).to be true
        end
      end
    end

    context 'with campaign emails' do
      let(:campaign) { create(:email_campaign, company: company) }
      let(:sequence) { create(:email_sequence, email_campaign: campaign) }
      let!(:email_queue) do
        ActsAsTenant.with_tenant(company) do
          create(:email_queue,
                 :sent,
                 :with_campaign,
                 company: company,
                 recipient: 'campaign@example.com',
                 email_campaign: campaign,
                 email_sequence: sequence,
                 metadata: { sendgrid_message_id: 'msg-campaign' })
        end
      end

      let(:event_data) do
        {
          'event' => 'delivered',
          'email' => 'campaign@example.com',
          'sg_message_id' => 'msg-campaign',
          'timestamp' => Time.current.to_i
        }
      end

      it 'updates campaign email metrics' do
        ActsAsTenant.with_tenant(company) do
          described_class.perform_now(event_data)

          expect(email_queue.reload.delivered_at).to be_present
          expect(email_queue.email_campaign_id).to eq(campaign.id)
          expect(email_queue.email_sequence_id).to eq(sequence.id)
        end
      end
    end

    context 'when email queue not found' do
      let(:event_data) do
        {
          'event' => 'delivered',
          'email' => 'notfound@example.com',
          'sg_message_id' => 'msg-notfound',
          'timestamp' => Time.current.to_i
        }
      end

      it 'does not raise an error' do
        ActsAsTenant.with_tenant(company) do
          expect {
            described_class.perform_now(event_data)
          }.not_to raise_error
        end
      end

      it 'logs the event' do
        ActsAsTenant.with_tenant(company) do
          expect(Rails.logger).to receive(:warn).with(/Email queue not found/)

          described_class.perform_now(event_data)
        end
      end
    end

    context 'with invalid event type' do
      let(:event_data) do
        {
          'event' => 'unknown_event',
          'email' => 'test@example.com',
          'sg_message_id' => 'msg-test',
          'timestamp' => Time.current.to_i
        }
      end

      it 'does not raise an error' do
        expect {
          described_class.perform_now(event_data)
        }.not_to raise_error
      end
    end

    context 'batch webhook processing' do
      let(:batch_events) do
        [
          {
            'event' => 'delivered',
            'email' => 'batch1@example.com',
            'sg_message_id' => 'msg-batch1',
            'timestamp' => Time.current.to_i
          },
          {
            'event' => 'open',
            'email' => 'batch2@example.com',
            'sg_message_id' => 'msg-batch2',
            'timestamp' => Time.current.to_i
          }
        ]
      end

      let!(:email_queue1) do
        ActsAsTenant.with_tenant(company) do
          create(:email_queue,
                 :sent,
                 company: company,
                 recipient: 'batch1@example.com',
                 metadata: { sendgrid_message_id: 'msg-batch1' })
        end
      end

      let!(:email_queue2) do
        ActsAsTenant.with_tenant(company) do
          create(:email_queue,
                 :sent,
                 company: company,
                 recipient: 'batch2@example.com',
                 metadata: { sendgrid_message_id: 'msg-batch2' })
        end
      end

      it 'processes all events in batch' do
        ActsAsTenant.with_tenant(company) do
          batch_events.each do |event|
            described_class.perform_now(event)
          end

          expect(email_queue1.reload.delivered_at).to be_present
          expect(email_queue2.reload.opened_at).to be_present
        end
      end
    end
  end
end
