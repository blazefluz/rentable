# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::EmailCampaigns', type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company, role: :admin) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{user.generate_jwt}" } }

  describe 'GET /api/v1/email_campaigns' do
    before do
      ActsAsTenant.with_tenant(company) do
        create_list(:email_campaign, 3, company: company)
      end
    end

    it 'returns all email campaigns for the company' do
      get '/api/v1/email_campaigns', headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['email_campaigns'].count).to eq(3)
    end

    it 'does not return campaigns from other companies' do
      other_company = create(:company)
      ActsAsTenant.with_tenant(other_company) do
        create(:email_campaign, company: other_company)
      end

      get '/api/v1/email_campaigns', headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['email_campaigns'].count).to eq(3)
    end

    it 'filters by campaign_type' do
      ActsAsTenant.with_tenant(company) do
        create(:email_campaign, :quote_followup, company: company)
      end

      get '/api/v1/email_campaigns', params: { campaign_type: 'quote_followup' }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['email_campaigns'].all? { |c| c['campaign_type'] == 'quote_followup' }).to be true
    end

    it 'filters by status' do
      ActsAsTenant.with_tenant(company) do
        create(:email_campaign, :active, company: company)
      end

      get '/api/v1/email_campaigns', params: { status: 'active' }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['email_campaigns'].all? { |c| c['status'] == 'active' }).to be true
    end
  end

  describe 'GET /api/v1/email_campaigns/:id' do
    let(:email_campaign) do
      ActsAsTenant.with_tenant(company) do
        create(:email_campaign, :with_sequences, company: company)
      end
    end

    it 'returns the email campaign' do
      get "/api/v1/email_campaigns/#{email_campaign.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['email_campaign']['id']).to eq(email_campaign.id)
    end

    it 'includes email sequences' do
      get "/api/v1/email_campaigns/#{email_campaign.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['email_campaign']['email_sequences']).to be_present
      expect(json['email_campaign']['email_sequences'].count).to eq(2)
    end

    it 'returns 404 for non-existent campaign' do
      get '/api/v1/email_campaigns/999999', headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/email_campaigns' do
    let(:valid_params) do
      {
        email_campaign: {
          name: 'New Quote Follow-up',
          campaign_type: 'quote_followup',
          status: 'draft',
          active: true,
          delay_hours: 24,
          trigger_conditions: { on_quote_sent: true }
        }
      }
    end

    it 'creates a new email campaign' do
      expect {
        post '/api/v1/email_campaigns', params: valid_params, headers: auth_headers
      }.to change(EmailCampaign, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it 'returns the created campaign' do
      post '/api/v1/email_campaigns', params: valid_params, headers: auth_headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['email_campaign']['name']).to eq('New Quote Follow-up')
      expect(json['email_campaign']['campaign_type']).to eq('quote_followup')
    end

    it 'automatically creates default sequences for quote_followup campaigns' do
      params = valid_params.merge(
        email_campaign: valid_params[:email_campaign].merge(campaign_type: 'quote_followup')
      )

      post '/api/v1/email_campaigns', params: params, headers: auth_headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      campaign = EmailCampaign.find(json['email_campaign']['id'])
      expect(campaign.email_sequences.count).to eq(2)
    end

    it 'returns errors for invalid params' do
      invalid_params = { email_campaign: { name: '' } }

      post '/api/v1/email_campaigns', params: invalid_params, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end

    it 'associates campaign with current company' do
      post '/api/v1/email_campaigns', params: valid_params, headers: auth_headers

      campaign = EmailCampaign.last
      expect(campaign.company_id).to eq(company.id)
    end
  end

  describe 'PATCH /api/v1/email_campaigns/:id' do
    let(:email_campaign) do
      ActsAsTenant.with_tenant(company) do
        create(:email_campaign, company: company)
      end
    end

    it 'updates the email campaign' do
      patch "/api/v1/email_campaigns/#{email_campaign.id}",
            params: { email_campaign: { name: 'Updated Name' } },
            headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(email_campaign.reload.name).to eq('Updated Name')
    end

    it 'returns the updated campaign' do
      patch "/api/v1/email_campaigns/#{email_campaign.id}",
            params: { email_campaign: { name: 'Updated Name' } },
            headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['email_campaign']['name']).to eq('Updated Name')
    end

    it 'returns errors for invalid params' do
      patch "/api/v1/email_campaigns/#{email_campaign.id}",
            params: { email_campaign: { name: '' } },
            headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE /api/v1/email_campaigns/:id' do
    let!(:email_campaign) do
      ActsAsTenant.with_tenant(company) do
        create(:email_campaign, company: company)
      end
    end

    it 'deletes the email campaign' do
      expect {
        delete "/api/v1/email_campaigns/#{email_campaign.id}", headers: auth_headers
      }.to change(EmailCampaign, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'GET /api/v1/email_campaigns/:id/analytics' do
    let(:email_campaign) do
      ActsAsTenant.with_tenant(company) do
        create(:email_campaign, company: company)
      end
    end

    before do
      ActsAsTenant.with_tenant(company) do
        create_list(:email_queue, 5, email_campaign: email_campaign)
        create_list(:email_queue, 2, email_campaign: email_campaign, opened_at: Time.current)
        create_list(:email_queue, 1, email_campaign: email_campaign, clicked_at: Time.current)
      end
    end

    it 'returns campaign analytics' do
      get "/api/v1/email_campaigns/#{email_campaign.id}/analytics", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['analytics']['total_sent']).to eq(8)
      expect(json['analytics']['opened']).to eq(2)
      expect(json['analytics']['clicked']).to eq(1)
    end

    it 'calculates open and click rates' do
      get "/api/v1/email_campaigns/#{email_campaign.id}/analytics", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['analytics']['open_rate']).to be_within(0.01).of(25.0) # 2/8 * 100
      expect(json['analytics']['click_rate']).to be_within(0.01).of(12.5) # 1/8 * 100
    end
  end

  describe 'POST /api/v1/email_campaigns/:id/send' do
    let(:email_campaign) do
      ActsAsTenant.with_tenant(company) do
        create(:email_campaign, :active, :with_sequences, company: company)
      end
    end
    let(:booking) do
      ActsAsTenant.with_tenant(company) do
        create(:booking, company: company, quote_status: 'pending_quotes')
      end
    end

    it 'enqueues SendEmailCampaignJob' do
      expect {
        post "/api/v1/email_campaigns/#{email_campaign.id}/send",
             params: { booking_id: booking.id },
             headers: auth_headers
      }.to have_enqueued_job(SendEmailCampaignJob)

      expect(response).to have_http_status(:ok)
    end

    it 'returns success message' do
      post "/api/v1/email_campaigns/#{email_campaign.id}/send",
           params: { booking_id: booking.id },
           headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to include('Campaign queued')
    end
  end

  describe 'POST /api/v1/email_campaigns/:id/pause' do
    let(:email_campaign) do
      ActsAsTenant.with_tenant(company) do
        create(:email_campaign, :active, company: company)
      end
    end

    it 'pauses the campaign' do
      post "/api/v1/email_campaigns/#{email_campaign.id}/pause", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(email_campaign.reload.status).to eq('paused')
    end
  end

  describe 'POST /api/v1/email_campaigns/:id/resume' do
    let(:email_campaign) do
      ActsAsTenant.with_tenant(company) do
        create(:email_campaign, :paused, company: company)
      end
    end

    it 'resumes the campaign' do
      post "/api/v1/email_campaigns/#{email_campaign.id}/resume", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(email_campaign.reload.status).to eq('active')
    end
  end

  describe 'authorization' do
    it 'requires authentication' do
      get '/api/v1/email_campaigns'

      expect(response).to have_http_status(:unauthorized)
    end

    context 'with non-admin user' do
      let(:regular_user) { create(:user, company: company, role: :user) }
      let(:regular_auth_headers) { { 'Authorization' => "Bearer #{regular_user.generate_jwt}" } }

      it 'allows viewing campaigns' do
        get '/api/v1/email_campaigns', headers: regular_auth_headers

        expect(response).to have_http_status(:ok)
      end

      it 'prevents creating campaigns' do
        params = {
          email_campaign: {
            name: 'Test Campaign',
            campaign_type: 'marketing',
            status: 'draft'
          }
        }

        post '/api/v1/email_campaigns', params: params, headers: regular_auth_headers

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
