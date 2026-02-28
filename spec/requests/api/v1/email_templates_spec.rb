# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::EmailTemplates', type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company, role: :admin) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{user.generate_jwt}" } }

  describe 'GET /api/v1/email_templates' do
    before do
      ActsAsTenant.with_tenant(company) do
        create_list(:email_template, 3, company: company)
      end
    end

    it 'returns all email templates for the company' do
      get '/api/v1/email_templates', headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['email_templates'].count).to eq(3)
    end

    it 'does not return templates from other companies' do
      other_company = create(:company)
      ActsAsTenant.with_tenant(other_company) do
        create(:email_template, company: other_company)
      end

      get '/api/v1/email_templates', headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['email_templates'].count).to eq(3)
    end

    it 'filters by category' do
      ActsAsTenant.with_tenant(company) do
        create(:email_template, :booking, company: company)
      end

      get '/api/v1/email_templates', params: { category: 'booking' }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['email_templates'].all? { |t| t['category'] == 'booking' }).to be true
    end

    it 'filters by active status' do
      ActsAsTenant.with_tenant(company) do
        create(:email_template, :inactive, company: company)
      end

      get '/api/v1/email_templates', params: { active: true }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['email_templates'].all? { |t| t['active'] == true }).to be true
    end
  end

  describe 'GET /api/v1/email_templates/:id' do
    let(:email_template) do
      ActsAsTenant.with_tenant(company) do
        create(:email_template, company: company)
      end
    end

    it 'returns the email template' do
      get "/api/v1/email_templates/#{email_template.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['email_template']['id']).to eq(email_template.id)
    end

    it 'includes variable schema' do
      get "/api/v1/email_templates/#{email_template.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['email_template']['variable_schema']).to be_present
    end

    it 'returns 404 for non-existent template' do
      get '/api/v1/email_templates/999999', headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/email_templates' do
    let(:valid_params) do
      {
        email_template: {
          name: 'New Template',
          category: 'booking',
          subject: 'Booking {{booking_reference}}',
          html_body: '<p>Hi {{customer_name}}</p>',
          text_body: 'Hi {{customer_name}}',
          active: true
        }
      }
    end

    it 'creates a new email template' do
      expect {
        post '/api/v1/email_templates', params: valid_params, headers: auth_headers
      }.to change(EmailTemplate, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it 'returns the created template' do
      post '/api/v1/email_templates', params: valid_params, headers: auth_headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['email_template']['name']).to eq('New Template')
      expect(json['email_template']['category']).to eq('booking')
    end

    it 'automatically extracts variables from templates' do
      post '/api/v1/email_templates', params: valid_params, headers: auth_headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      template = EmailTemplate.find(json['email_template']['id'])
      expect(template.available_variables).to include('booking_reference', 'customer_name')
    end

    it 'returns errors for invalid params' do
      invalid_params = { email_template: { name: '' } }

      post '/api/v1/email_templates', params: invalid_params, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end

    it 'associates template with current company' do
      post '/api/v1/email_templates', params: valid_params, headers: auth_headers

      template = EmailTemplate.last
      expect(template.company_id).to eq(company.id)
    end
  end

  describe 'PATCH /api/v1/email_templates/:id' do
    let(:email_template) do
      ActsAsTenant.with_tenant(company) do
        create(:email_template, company: company)
      end
    end

    it 'updates the email template' do
      patch "/api/v1/email_templates/#{email_template.id}",
            params: { email_template: { name: 'Updated Template' } },
            headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(email_template.reload.name).to eq('Updated Template')
    end

    it 'returns the updated template' do
      patch "/api/v1/email_templates/#{email_template.id}",
            params: { email_template: { name: 'Updated Template' } },
            headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['email_template']['name']).to eq('Updated Template')
    end

    it 'updates variable schema when content changes' do
      patch "/api/v1/email_templates/#{email_template.id}",
            params: {
              email_template: {
                subject: 'New {{variable}} here',
                html_body: '<p>{{another_variable}}</p>'
              }
            },
            headers: auth_headers

      expect(response).to have_http_status(:ok)
      template = email_template.reload
      expect(template.available_variables).to include('variable', 'another_variable')
    end

    it 'returns errors for invalid params' do
      patch "/api/v1/email_templates/#{email_template.id}",
            params: { email_template: { name: '' } },
            headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE /api/v1/email_templates/:id' do
    let!(:email_template) do
      ActsAsTenant.with_tenant(company) do
        create(:email_template, company: company)
      end
    end

    it 'deletes the email template' do
      expect {
        delete "/api/v1/email_templates/#{email_template.id}", headers: auth_headers
      }.to change(EmailTemplate, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'POST /api/v1/email_templates/:id/preview' do
    let(:email_template) do
      ActsAsTenant.with_tenant(company) do
        create(:email_template,
               company: company,
               subject: 'Quote {{quote_number}} for {{customer_name}}',
               html_body: '<p>Hi {{customer_name}}, your total is {{total}}</p>')
      end
    end

    let(:preview_params) do
      {
        variables: {
          quote_number: 'Q-12345',
          customer_name: 'Acme Corp',
          total: '$1,000'
        }
      }
    end

    it 'returns preview with substituted variables' do
      post "/api/v1/email_templates/#{email_template.id}/preview",
           params: preview_params,
           headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['preview']['subject']).to eq('Quote Q-12345 for Acme Corp')
      expect(json['preview']['html_body']).to include('Hi Acme Corp')
      expect(json['preview']['html_body']).to include('$1,000')
    end

    it 'leaves unreplaced variables in preview' do
      partial_params = {
        variables: {
          customer_name: 'Acme Corp'
        }
      }

      post "/api/v1/email_templates/#{email_template.id}/preview",
           params: partial_params,
           headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['preview']['subject']).to include('{{quote_number}}')
      expect(json['preview']['subject']).to include('Acme Corp')
    end
  end

  describe 'POST /api/v1/email_templates/:id/duplicate' do
    let(:email_template) do
      ActsAsTenant.with_tenant(company) do
        create(:email_template, company: company, name: 'Original Template')
      end
    end

    it 'creates a duplicate template' do
      expect {
        post "/api/v1/email_templates/#{email_template.id}/duplicate", headers: auth_headers
      }.to change(EmailTemplate, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it 'appends (Copy) to the name' do
      post "/api/v1/email_templates/#{email_template.id}/duplicate", headers: auth_headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['email_template']['name']).to eq('Original Template (Copy)')
    end

    it 'sets the duplicate as inactive' do
      post "/api/v1/email_templates/#{email_template.id}/duplicate", headers: auth_headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['email_template']['active']).to be false
    end
  end

  describe 'authorization' do
    it 'requires authentication' do
      get '/api/v1/email_templates'

      expect(response).to have_http_status(:unauthorized)
    end

    context 'with non-admin user' do
      let(:regular_user) { create(:user, company: company, role: :user) }
      let(:regular_auth_headers) { { 'Authorization' => "Bearer #{regular_user.generate_jwt}" } }

      it 'allows viewing templates' do
        get '/api/v1/email_templates', headers: regular_auth_headers

        expect(response).to have_http_status(:ok)
      end

      it 'prevents creating templates' do
        params = {
          email_template: {
            name: 'Test Template',
            category: 'marketing',
            subject: 'Test',
            html_body: '<p>Test</p>'
          }
        }

        post '/api/v1/email_templates', params: params, headers: regular_auth_headers

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
