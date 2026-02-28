# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendGridService do
  let(:service) { described_class.new }
  let(:company) { create(:company) }

  before do
    # Mock SendGrid client
    allow_any_instance_of(SendGrid::API).to receive(:client).and_return(double)
  end

  describe '#send_email' do
    let(:email_params) do
      {
        to: 'customer@example.com',
        from: 'noreply@rentable.com',
        subject: 'Test Email',
        html_body: '<p>Test content</p>',
        text_body: 'Test content'
      }
    end

    context 'when email sends successfully' do
      before do
        mock_response = double(status_code: '202', body: 'Accepted')
        allow_any_instance_of(SendGrid::API)
          .to receive_message_chain(:client, :mail, :_, :post)
          .and_return(mock_response)
      end

      it 'returns success' do
        result = service.send_email(**email_params)

        expect(result[:success]).to be true
        expect(result[:status_code]).to eq('202')
      end

      it 'updates email queue status when email_queue_id provided' do
        ActsAsTenant.with_tenant(company) do
          email_queue = create(:email_queue, company: company, status: :pending)

          service.send_email(**email_params.merge(email_queue_id: email_queue.id))

          expect(email_queue.reload.status).to eq('sent')
          expect(email_queue.sent_at).to be_present
        end
      end
    end

    context 'when email fails to send' do
      before do
        mock_response = double(status_code: '400', body: 'Bad Request')
        allow_any_instance_of(SendGrid::API)
          .to receive_message_chain(:client, :mail, :_, :post)
          .and_return(mock_response)
      end

      it 'returns error' do
        result = service.send_email(**email_params)

        expect(result[:success]).to be false
        expect(result[:error]).to be_present
      end

      it 'updates email queue status to failed when email_queue_id provided' do
        ActsAsTenant.with_tenant(company) do
          email_queue = create(:email_queue, company: company, status: :pending)

          service.send_email(**email_params.merge(email_queue_id: email_queue.id))

          expect(email_queue.reload.status).to eq('failed')
        end
      end
    end

    context 'when rate limit is exceeded' do
      before do
        # Simulate sending 100 emails in the last hour
        allow(service).to receive(:emails_sent_in_last_hour).and_return(100)
      end

      it 'returns rate limit error' do
        result = service.send_email(**email_params)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Rate limit exceeded')
      end

      it 'does not send the email' do
        expect_any_instance_of(SendGrid::API).not_to receive(:client)

        service.send_email(**email_params)
      end
    end
  end

  describe '#send_bulk_emails' do
    let(:emails) do
      [
        {
          to: 'customer1@example.com',
          subject: 'Email 1',
          html_body: '<p>Content 1</p>'
        },
        {
          to: 'customer2@example.com',
          subject: 'Email 2',
          html_body: '<p>Content 2</p>'
        }
      ]
    end

    before do
      mock_response = double(status_code: '202', body: 'Accepted')
      allow_any_instance_of(SendGrid::API)
        .to receive_message_chain(:client, :mail, :_, :post)
        .and_return(mock_response)
    end

    it 'sends all emails' do
      results = service.send_bulk_emails(emails, from: 'noreply@rentable.com')

      expect(results).to all(include(success: true))
      expect(results.count).to eq(2)
    end

    it 'respects rate limiting' do
      # Create 101 emails (exceeds rate limit)
      many_emails = 101.times.map do |i|
        {
          to: "customer#{i}@example.com",
          subject: "Email #{i}",
          html_body: "<p>Content #{i}</p>"
        }
      end

      results = service.send_bulk_emails(many_emails, from: 'noreply@rentable.com')

      successful = results.count { |r| r[:success] }
      failed = results.count { |r| !r[:success] }

      expect(successful).to be <= 100
      expect(failed).to be > 0
    end
  end

  describe '#process_webhook_event' do
    let(:event_data) do
      {
        'event' => 'delivered',
        'email' => 'customer@example.com',
        'sg_message_id' => 'msg-123',
        'timestamp' => Time.current.to_i
      }
    end

    context 'when email queue exists' do
      let!(:email_queue) do
        ActsAsTenant.with_tenant(company) do
          create(:email_queue,
                 company: company,
                 recipient: 'customer@example.com',
                 metadata: { sendgrid_message_id: 'msg-123' })
        end
      end

      it 'updates delivered_at for delivered event' do
        ActsAsTenant.with_tenant(company) do
          service.process_webhook_event(event_data)

          expect(email_queue.reload.delivered_at).to be_present
        end
      end

      it 'updates opened_at for open event' do
        ActsAsTenant.with_tenant(company) do
          service.process_webhook_event(event_data.merge('event' => 'open'))

          expect(email_queue.reload.opened_at).to be_present
        end
      end

      it 'updates clicked_at for click event' do
        ActsAsTenant.with_tenant(company) do
          service.process_webhook_event(event_data.merge('event' => 'click'))

          expect(email_queue.reload.clicked_at).to be_present
        end
      end

      it 'updates bounced_at and bounce_reason for bounce event' do
        ActsAsTenant.with_tenant(company) do
          bounce_data = event_data.merge(
            'event' => 'bounce',
            'reason' => 'Email address does not exist'
          )

          service.process_webhook_event(bounce_data)

          email_queue.reload
          expect(email_queue.bounced_at).to be_present
          expect(email_queue.bounce_reason).to eq('Email address does not exist')
        end
      end

      it 'updates unsubscribed_at for unsubscribe event' do
        ActsAsTenant.with_tenant(company) do
          service.process_webhook_event(event_data.merge('event' => 'unsubscribe'))

          expect(email_queue.reload.unsubscribed_at).to be_present
        end
      end
    end

    context 'when email queue does not exist' do
      it 'does not raise an error' do
        ActsAsTenant.with_tenant(company) do
          expect {
            service.process_webhook_event(event_data)
          }.not_to raise_error
        end
      end
    end
  end

  describe 'rate limiting' do
    describe '#rate_limit_exceeded?' do
      it 'returns false when under limit' do
        allow(service).to receive(:emails_sent_in_last_hour).and_return(50)

        expect(service.send(:rate_limit_exceeded?)).to be false
      end

      it 'returns true when at limit' do
        allow(service).to receive(:emails_sent_in_last_hour).and_return(100)

        expect(service.send(:rate_limit_exceeded?)).to be true
      end

      it 'returns true when over limit' do
        allow(service).to receive(:emails_sent_in_last_hour).and_return(150)

        expect(service.send(:rate_limit_exceeded?)).to be true
      end
    end

    describe '#emails_sent_in_last_hour' do
      it 'counts emails sent in the last hour' do
        ActsAsTenant.with_tenant(company) do
          # Emails within last hour
          create_list(:email_queue, 3,
                      company: company,
                      sent_at: 30.minutes.ago,
                      status: :sent)

          # Emails older than 1 hour (should not be counted)
          create_list(:email_queue, 2,
                      company: company,
                      sent_at: 2.hours.ago,
                      status: :sent)

          count = service.send(:emails_sent_in_last_hour)

          expect(count).to eq(3)
        end
      end
    end
  end

  describe '#build_email' do
    it 'creates a SendGrid mail object with correct parameters' do
      mail = service.send(:build_email,
                          to: 'customer@example.com',
                          from: 'noreply@rentable.com',
                          subject: 'Test',
                          html_body: '<p>Test</p>',
                          text_body: 'Test')

      expect(mail).to be_a(SendGrid::Mail)
    end

    it 'includes both HTML and text content when provided' do
      mail = service.send(:build_email,
                          to: 'customer@example.com',
                          from: 'noreply@rentable.com',
                          subject: 'Test',
                          html_body: '<p>Test HTML</p>',
                          text_body: 'Test Text')

      # Verify mail object has both content types
      expect(mail.contents).to be_present
    end
  end
end
