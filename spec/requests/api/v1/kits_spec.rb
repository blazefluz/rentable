require 'rails_helper'

RSpec.describe 'Api::V1::Kits', type: :request do
  let!(:kits) { create_list(:kit, 3) }
  let(:kit) { kits.first }

  describe 'GET /api/v1/kits' do
    it 'returns all kits' do
      get '/api/v1/kits'
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['kits'].length).to eq(3)
    end

    it 'includes kit items' do
      kit.kit_items.create(product: create(:product), quantity: 1)
      get '/api/v1/kits'
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      kit_json = json['kits'].find { |k| k['id'] == kit.id }
      expect(kit_json).to have_key('kit_items')
    end
  end

  describe 'GET /api/v1/kits/:id' do
    it 'returns a kit with items' do
      create(:kit_item, kit: kit, product: create(:product))
      get "/api/v1/kits/#{kit.id}"
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['kit']['id']).to eq(kit.id)
      expect(json['kit']['kit_items']).to be_present
    end

    it 'returns 404 for non-existent kit' do
      get '/api/v1/kits/9999'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/kits' do
    let(:product) { create(:product) }
    let(:valid_params) do
      {
        kit: {
          name: 'Test Kit',
          description: 'Test description',
          daily_price_cents: 10000,
          kit_items_attributes: [
            {
              product_id: product.id,
              quantity: 1
            }
          ]
        }
      }
    end

    it 'creates a new kit with items' do
      expect {
        post '/api/v1/kits', params: valid_params
      }.to change(Kit, :count).by(1)
        .and change(KitItem, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it 'returns error for invalid params' do
      post '/api/v1/kits', params: { kit: { name: '' } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/kits/:id' do
    it 'updates a kit' do
      patch "/api/v1/kits/#{kit.id}", params: { kit: { name: 'Updated Kit' } }
      expect(response).to have_http_status(:success)
      expect(kit.reload.name).to eq('Updated Kit')
    end
  end

  describe 'DELETE /api/v1/kits/:id' do
    it 'archives a kit' do
      delete "/api/v1/kits/#{kit.id}"
      expect(response).to have_http_status(:success)
      expect(kit.reload.active).to be false
    end
  end

  describe 'GET /api/v1/kits/:id/availability' do
    let(:kit_with_items) { create(:kit, :with_items) }

    it 'checks kit availability' do
      start_date = 10.days.from_now
      end_date = 15.days.from_now
      get "/api/v1/kits/#{kit_with_items.id}/availability",
          params: { start_date: start_date, end_date: end_date, quantity: 1 }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('is_available')
    end
  end
end
