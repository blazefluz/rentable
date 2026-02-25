require 'rails_helper'

RSpec.describe 'Api::V1::Products', type: :request do
  let!(:products) { create_list(:product, 3) }
  let(:product) { products.first }

  describe 'GET /api/v1/products' do
    it 'returns all products' do
      get '/api/v1/products'
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['products'].length).to eq(3)
    end

    it 'filters by category' do
      camera = create(:product, category: 'Camera')
      get '/api/v1/products', params: { category: 'Camera' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['products'].any? { |p| p['id'] == camera.id }).to be true
    end

    it 'paginates results' do
      create_list(:product, 20)
      get '/api/v1/products', params: { page: 1, per_page: 10 }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['products'].length).to eq(10)
    end
  end

  describe 'GET /api/v1/products/:id' do
    it 'returns a product' do
      get "/api/v1/products/#{product.id}"
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['product']['id']).to eq(product.id)
    end

    it 'returns 404 for non-existent product' do
      get '/api/v1/products/9999'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/products' do
    let(:valid_params) do
      {
        product: {
          name: 'Test Product',
          description: 'Test description',
          daily_price_cents: 5000,
          quantity: 5,
          category: 'Camera'
        }
      }
    end

    it 'creates a new product' do
      expect {
        post '/api/v1/products', params: valid_params
      }.to change(Product, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it 'returns error for invalid params' do
      post '/api/v1/products', params: { product: { name: '' } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/products/:id' do
    it 'updates a product' do
      patch "/api/v1/products/#{product.id}", params: { product: { name: 'Updated Name' } }
      expect(response).to have_http_status(:success)
      expect(product.reload.name).to eq('Updated Name')
    end
  end

  describe 'DELETE /api/v1/products/:id' do
    it 'archives a product' do
      delete "/api/v1/products/#{product.id}"
      expect(response).to have_http_status(:success)
      expect(product.reload.active).to be false
    end
  end

  describe 'GET /api/v1/products/:id/availability' do
    it 'checks product availability' do
      start_date = 10.days.from_now
      end_date = 15.days.from_now
      get "/api/v1/products/#{product.id}/availability",
          params: { start_date: start_date, end_date: end_date, quantity: 1 }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('is_available')
    end
  end

  describe 'GET /api/v1/products/search_by_barcode/:barcode' do
    it 'searches product by barcode' do
      product.update(barcode: 'TEST123')
      get '/api/v1/products/search_by_barcode/TEST123'
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['product']['id']).to eq(product.id)
    end

    it 'returns 404 for non-existent barcode' do
      get '/api/v1/products/search_by_barcode/NONEXISTENT'
      expect(response).to have_http_status(:not_found)
    end
  end
end
