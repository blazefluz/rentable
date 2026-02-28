require 'rails_helper'

RSpec.describe 'Api::V1::Bookings', type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, :admin, company: company) }
  let(:client) { create(:client, company: company) }
  let!(:bookings) { create_list(:booking, 3, company: company) }
  let(:booking) { bookings.first }
  let(:auth_headers) { { 'Authorization' => "Bearer #{user.generate_jwt}", 'Content-Type' => 'application/json' } }

  before do
    ActsAsTenant.current_tenant = company
  end

  describe 'GET /api/v1/bookings' do
    it 'returns all bookings' do
      get '/api/v1/bookings', headers: auth_headers
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['bookings'].length).to eq(3)
    end

    it 'filters by status' do
      confirmed = create(:booking, status: :confirmed, company: company)
      get '/api/v1/bookings', headers: auth_headers, params: { status: 'confirmed' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['bookings'].any? { |b| b['id'] == confirmed.id }).to be true
    end

    it 'searches by customer name' do
      booking.update(customer_name: 'John Doe')
      get '/api/v1/bookings', headers: auth_headers, params: { search: 'John' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['bookings'].any? { |b| b['id'] == booking.id }).to be true
    end
  end

  describe 'GET /api/v1/bookings/:id' do
    it 'returns a booking with line items' do
      create(:booking_line_item, booking: booking)
      get "/api/v1/bookings/#{booking.id}", headers: auth_headers
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['booking']['id']).to eq(booking.id)
      expect(json['booking']).to have_key('line_items')
      expect(json['booking']['line_items']).to be_an(Array)
    end

    it 'returns 404 for non-existent booking' do
      get '/api/v1/bookings/9999', headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/bookings' do
    let(:product) { create(:product, company: company, quantity: 10) }
    let(:valid_params) do
      {
        booking: {
          start_date: 3.days.from_now,
          end_date: 7.days.from_now,
          customer_name: 'Test Customer',
          customer_email: 'test@example.com',
          customer_phone: '1234567890',
          booking_line_items_attributes: [
            {
              bookable_type: 'Product',
              bookable_id: product.id,
              quantity: 1,
              price_cents: product.daily_price_cents
            }
          ]
        }
      }
    end

    it 'creates a new booking with line items' do
      expect {
        post '/api/v1/bookings', params: valid_params, headers: auth_headers, as: :json
      }.to change(Booking, :count).by(1)
        .and change(BookingLineItem, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it 'returns error for invalid params' do
      post '/api/v1/bookings', params: { booking: { customer_name: '' } }, headers: auth_headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/bookings/:id' do
    it 'updates a booking' do
      patch "/api/v1/bookings/#{booking.id}",
            params: { booking: { customer_name: 'Updated Name' } }, headers: auth_headers, as: :json
      expect(response).to have_http_status(:success)
      expect(booking.reload.customer_name).to eq('Updated Name')
    end
  end

  describe 'DELETE /api/v1/bookings/:id' do
    it 'soft deletes a booking' do
      delete "/api/v1/bookings/#{booking.id}", headers: auth_headers
      expect(response).to have_http_status(:success)
      expect(booking.reload.deleted).to be true
    end
  end

  describe 'PATCH /api/v1/bookings/:id/confirm' do
    let(:pending_booking) { create(:booking, :pending, company: company) }

    it 'confirms a booking' do
      patch "/api/v1/bookings/#{pending_booking.id}/confirm", headers: auth_headers
      expect(response).to have_http_status(:success)
      expect(pending_booking.reload).to be_status_confirmed
    end
  end

  describe 'PATCH /api/v1/bookings/:id/cancel' do
    it 'cancels a booking' do
      patch "/api/v1/bookings/#{booking.id}/cancel", headers: auth_headers
      expect(response).to have_http_status(:success)
      expect(booking.reload).to be_status_cancelled
    end
  end
end
