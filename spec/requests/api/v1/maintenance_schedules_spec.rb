require 'rails_helper'

RSpec.describe 'Api::V1::MaintenanceSchedules', type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }
  let(:product) { create(:product, company: company) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{user.generate_jwt}" } }

  describe 'GET /api/v1/maintenance_schedules' do
    let!(:schedule1) { create(:maintenance_schedule, product: product, company: company, name: 'Monthly Oil Change') }
    let!(:schedule2) { create(:maintenance_schedule, product: product, company: company, name: 'Quarterly Inspection') }

    it 'returns all maintenance schedules' do
      ActsAsTenant.with_tenant(company) do
        get '/api/v1/maintenance_schedules', headers: auth_headers

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['maintenance_schedules'].size).to eq(2)
        expect(json['meta']['total']).to eq(2)
      end
    end

    it 'filters by product_id' do
      other_product = create(:product, company: company)
      other_schedule = create(:maintenance_schedule, product: other_product, company: company)

      ActsAsTenant.with_tenant(company) do
        get "/api/v1/maintenance_schedules?product_id=#{product.id}", headers: auth_headers

        json = JSON.parse(response.body)
        expect(json['maintenance_schedules'].size).to eq(2)
        expect(json['maintenance_schedules'].map { |s| s['product_id'] }).to all(eq(product.id))
      end
    end

    it 'filters by status' do
      overdue_schedule = create(:maintenance_schedule, :overdue, product: product, company: company)

      ActsAsTenant.with_tenant(company) do
        get '/api/v1/maintenance_schedules?status=overdue', headers: auth_headers

        json = JSON.parse(response.body)
        expect(json['maintenance_schedules'].size).to eq(1)
        expect(json['maintenance_schedules'].first['status']).to eq('overdue')
      end
    end

    it 'filters by enabled' do
      disabled_schedule = create(:maintenance_schedule, :disabled, product: product, company: company)

      ActsAsTenant.with_tenant(company) do
        get '/api/v1/maintenance_schedules?enabled=true', headers: auth_headers

        json = JSON.parse(response.body)
        expect(json['maintenance_schedules'].map { |s| s['enabled'] }).to all(be true)
      end
    end
  end

  describe 'GET /api/v1/maintenance_schedules/due' do
    let!(:due_soon) { create(:maintenance_schedule, :due_soon, product: product, company: company) }
    let!(:not_due) { create(:maintenance_schedule, product: product, company: company, next_due_date: 30.days.from_now) }

    it 'returns schedules due within 7 days by default' do
      ActsAsTenant.with_tenant(company) do
        get '/api/v1/maintenance_schedules/due', headers: auth_headers

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['maintenance_schedules'].size).to eq(1)
        expect(json['meta']['days']).to eq(7)
      end
    end

    it 'respects custom days parameter' do
      ActsAsTenant.with_tenant(company) do
        get '/api/v1/maintenance_schedules/due?days=35', headers: auth_headers

        json = JSON.parse(response.body)
        expect(json['maintenance_schedules'].size).to eq(2)
        expect(json['meta']['days']).to eq(35)
      end
    end
  end

  describe 'GET /api/v1/maintenance_schedules/overdue' do
    let!(:overdue_schedule) { create(:maintenance_schedule, :overdue, product: product, company: company) }
    let!(:current_schedule) { create(:maintenance_schedule, product: product, company: company, next_due_date: 5.days.from_now) }

    it 'returns only overdue schedules' do
      ActsAsTenant.with_tenant(company) do
        get '/api/v1/maintenance_schedules/overdue', headers: auth_headers

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['maintenance_schedules'].size).to eq(1)
        expect(json['maintenance_schedules'].first['status']).to eq('overdue')
      end
    end
  end

  describe 'GET /api/v1/maintenance_schedules/:id' do
    let(:schedule) { create(:maintenance_schedule, product: product, company: company) }
    let!(:log) { create(:maintenance_log, maintenance_schedule: schedule, performed_by: user) }

    it 'returns schedule details with maintenance logs' do
      ActsAsTenant.with_tenant(company) do
        get "/api/v1/maintenance_schedules/#{schedule.id}", headers: auth_headers

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['maintenance_schedule']['id']).to eq(schedule.id)
        expect(json['maintenance_schedule']['name']).to eq(schedule.name)
        expect(json['maintenance_schedule']['maintenance_logs'].size).to eq(1)
      end
    end

    it 'returns 404 for non-existent schedule' do
      ActsAsTenant.with_tenant(company) do
        get "/api/v1/maintenance_schedules/#{SecureRandom.uuid}", headers: auth_headers

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Maintenance schedule not found')
      end
    end
  end

  describe 'POST /api/v1/maintenance_schedules' do
    let(:valid_params) do
      {
        product_id: product.id,
        maintenance_schedule: {
          name: 'Oil Change',
          description: 'Regular oil change maintenance',
          frequency: 'days_based',
          interval_value: 30,
          interval_unit: 'days',
          assigned_to_id: user.id
        }
      }
    end

    it 'creates a new maintenance schedule' do
      ActsAsTenant.with_tenant(company) do
        expect {
          post '/api/v1/maintenance_schedules', params: valid_params, headers: auth_headers
        }.to change(MaintenanceSchedule, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['maintenance_schedule']['name']).to eq('Oil Change')
        expect(json['maintenance_schedule']['frequency']).to eq('days_based')
        expect(json['maintenance_schedule']['next_due_date']).to be_present
        expect(json['message']).to eq('Maintenance schedule created successfully')
      end
    end

    it 'returns errors for invalid params' do
      ActsAsTenant.with_tenant(company) do
        invalid_params = valid_params.deep_merge(maintenance_schedule: { interval_value: -5 })

        post '/api/v1/maintenance_schedules', params: invalid_params, headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end
  end

  describe 'PATCH /api/v1/maintenance_schedules/:id' do
    let(:schedule) { create(:maintenance_schedule, product: product, company: company, name: 'Original Name') }

    it 'updates the maintenance schedule' do
      ActsAsTenant.with_tenant(company) do
        patch "/api/v1/maintenance_schedules/#{schedule.id}",
              params: { maintenance_schedule: { name: 'Updated Name', interval_value: 60 } },
              headers: auth_headers

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['maintenance_schedule']['name']).to eq('Updated Name')
        expect(json['maintenance_schedule']['interval_value']).to eq(60)
        expect(json['message']).to eq('Maintenance schedule updated successfully')
      end
    end

    it 'recalculates next_due_date when interval changes' do
      ActsAsTenant.with_tenant(company) do
        old_due_date = schedule.next_due_date

        patch "/api/v1/maintenance_schedules/#{schedule.id}",
              params: { maintenance_schedule: { interval_value: 60 } },
              headers: auth_headers

        schedule.reload
        # Next due date should be recalculated
        expect(schedule.next_due_date).not_to eq(old_due_date)
      end
    end
  end

  describe 'DELETE /api/v1/maintenance_schedules/:id' do
    it 'deletes the maintenance schedule' do
      ActsAsTenant.with_tenant(company) do
        schedule = create(:maintenance_schedule, product: product, company: company)

        expect {
          delete "/api/v1/maintenance_schedules/#{schedule.id}", headers: auth_headers
        }.to change(MaintenanceSchedule, :count).by(-1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Maintenance schedule deleted successfully')
      end
    end
  end

  describe 'POST /api/v1/maintenance_schedules/:id/complete' do
    let(:schedule) { create(:maintenance_schedule, product: product, company: company, status: :in_progress) }

    it 'completes the maintenance task' do
      ActsAsTenant.with_tenant(company) do
        expect {
          post "/api/v1/maintenance_schedules/#{schedule.id}/complete",
               params: { notes: 'Changed oil and filter' },
               headers: auth_headers
        }.to change { schedule.maintenance_logs.count }.by(1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['maintenance_schedule']['status']).to eq('scheduled')
        expect(json['maintenance_schedule']['last_completed_at']).to be_present
        expect(json['maintenance_log']['notes']).to eq('Changed oil and filter')
        expect(json['message']).to include('Maintenance completed successfully')
      end
    end

    it 'updates next_due_date after completion' do
      ActsAsTenant.with_tenant(company) do
        old_due_date = schedule.next_due_date

        post "/api/v1/maintenance_schedules/#{schedule.id}/complete",
             params: { notes: 'Completed' },
             headers: auth_headers

        schedule.reload
        expect(schedule.next_due_date).to be > old_due_date
      end
    end
  end

  describe 'authorization' do
    it 'requires authentication' do
      get '/api/v1/maintenance_schedules'
      # Response might be :unauthorized or :not_found depending on routing
      expect([401, 404]).to include(response.status)
    end

    it 'enforces tenant isolation' do
      other_company = create(:company)
      other_product = create(:product, company: other_company)
      other_schedule = create(:maintenance_schedule, product: other_product, company: other_company)

      ActsAsTenant.with_tenant(company) do
        get '/api/v1/maintenance_schedules', headers: auth_headers
        json = JSON.parse(response.body)

        # Should only see schedules from own company
        expect(json['maintenance_schedules'].map { |s| s['id'] }).not_to include(other_schedule.id)
      end
    end
  end
end
