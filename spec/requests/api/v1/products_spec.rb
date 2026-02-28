require 'rails_helper'

RSpec.describe 'Api::V1::Products', type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, :admin, company: company) }
  let!(:products) { create_list(:product, 5, company: company) }
  let(:product) { products.first }
  let(:auth_headers) { auth_headers_for(user) }

  before do
    ActsAsTenant.current_tenant = company
  end

  describe 'GET /api/v1/products' do
    context 'basic listing' do
      it 'returns all active products' do
        get '/api/v1/products', headers: auth_headers
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['products'].length).to eq(5)
        expect(json).to have_key('meta')
        expect(json['meta']).to have_key('total_count')
      end

      it 'includes product details in response' do
        get '/api/v1/products', headers: auth_headers
        json = JSON.parse(response.body)
        product_json = json['products'].first

        expect(product_json).to have_key('id')
        expect(product_json).to have_key('name')
        expect(product_json).to have_key('description')
        expect(product_json).to have_key('category')
        expect(product_json).to have_key('daily_price')
        expect(product_json).to have_key('quantity')
        expect(product_json).to have_key('available_quantity')
        expect(product_json).to have_key('active')
      end

      it 'paginates results' do
        create_list(:product, 30, company: company)
        get '/api/v1/products', headers: auth_headers, params: { per_page: 10 }
        json = JSON.parse(response.body)

        expect(json['products'].length).to eq(10)
        expect(json['meta']['total_pages']).to be > 1
        expect(json['meta']['current_page']).to eq(1)
      end
    end

    context 'filtering' do
      it 'filters by category' do
        camera = create(:product, category: 'Camera', company: company)
        get '/api/v1/products', headers: auth_headers, params: { category: 'Camera' }
        json = JSON.parse(response.body)

        expect(json['products'].any? { |p| p['id'] == camera.id }).to be true
        expect(json['filters_applied']['category']).to eq('Camera')
      end

      it 'searches by query' do
        product.update(name: 'Canon EOS R5 Camera')
        get '/api/v1/products', headers: auth_headers, params: { query: 'Canon' }
        json = JSON.parse(response.body)

        expect(json['products'].any? { |p| p['id'] == product.id }).to be true
      end

      it 'filters by price range' do
        cheap = create(:product, daily_price_cents: 1000, company: company)
        expensive = create(:product, daily_price_cents: 50000, company: company)

        get '/api/v1/products', headers: auth_headers, params: { min_price: 100, max_price: 200 }
        json = JSON.parse(response.body)

        expect(json['products'].any? { |p| p['id'] == expensive.id }).to be false
      end

      it 'filters by minimum quantity' do
        low_stock = create(:product, quantity: 1, company: company)
        high_stock = create(:product, quantity: 10, company: company)

        get '/api/v1/products', headers: auth_headers, params: { min_quantity: 5 }
        json = JSON.parse(response.body)

        expect(json['products'].any? { |p| p['id'] == high_stock.id }).to be true
        expect(json['products'].any? { |p| p['id'] == low_stock.id }).to be false
      end

      it 'excludes inactive products by default' do
        inactive = create(:product, :inactive, company: company)
        get '/api/v1/products', headers: auth_headers
        json = JSON.parse(response.body)

        expect(json['products'].any? { |p| p['id'] == inactive.id }).to be false
      end

      it 'includes inactive products when requested' do
        inactive = create(:product, :inactive, company: company)
        get '/api/v1/products', headers: auth_headers, params: { include_inactive: 'true' }
        json = JSON.parse(response.body)

        expect(json['products'].any? { |p| p['id'] == inactive.id }).to be true
      end

      it 'excludes archived products by default' do
        archived = create(:product, archived: true, company: company)
        get '/api/v1/products', headers: auth_headers
        json = JSON.parse(response.body)

        expect(json['products'].any? { |p| p['id'] == archived.id }).to be false
      end

      it 'includes archived products when requested' do
        archived = create(:product, archived: true, company: company)
        get '/api/v1/products', headers: auth_headers, params: { include_archived: 'true' }
        json = JSON.parse(response.body)

        expect(json['products'].any? { |p| p['id'] == archived.id }).to be true
      end
    end

    context 'sorting' do
      before do
        Product.destroy_all
        create(:product, name: 'Zebra', daily_price_cents: 5000, quantity: 3, company: company)
        create(:product, name: 'Apple', daily_price_cents: 10000, quantity: 1, company: company)
        create(:product, name: 'Banana', daily_price_cents: 2000, quantity: 5, company: company)
      end

      it 'sorts by name ascending' do
        get '/api/v1/products', headers: auth_headers, params: { sort_by: 'name', sort_order: 'asc' }
        json = JSON.parse(response.body)
        names = json['products'].map { |p| p['name'] }

        expect(names).to eq(['Apple', 'Banana', 'Zebra'])
      end

      it 'sorts by price descending' do
        get '/api/v1/products', headers: auth_headers, params: { sort_by: 'price', sort_order: 'desc' }
        json = JSON.parse(response.body)
        prices = json['products'].map { |p| p['daily_price']['amount'] }

        expect(prices).to eq([10000, 5000, 2000])
      end

      it 'sorts by quantity ascending' do
        get '/api/v1/products', headers: auth_headers, params: { sort_by: 'quantity', sort_order: 'asc' }
        json = JSON.parse(response.body)
        quantities = json['products'].map { |p| p['quantity'] }

        expect(quantities).to eq([1, 3, 5])
      end
    end
  end

  describe 'GET /api/v1/products/:id' do
    it 'returns a single product with full details' do
      get "/api/v1/products/#{product.id}", headers: auth_headers
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json['product']['id']).to eq(product.id)
      expect(json['product']['name']).to eq(product.name)
      expect(json['product']).to have_key('serial_numbers')
      expect(json['product']).to have_key('custom_fields')
      expect(json['product']).to have_key('images')
    end

    it 'returns 404 for non-existent product' do
      get '/api/v1/products/99999', headers: auth_headers
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Product not found')
    end

    it 'includes storage location when associated' do
      location = create(:location, company: company)
      product.update(storage_location: location)

      get "/api/v1/products/#{product.id}", headers: auth_headers
      json = JSON.parse(response.body)

      expect(json['product']['storage_location']).to be_present
      expect(json['product']['storage_location']['id']).to eq(location.id)
    end
  end

  describe 'POST /api/v1/products' do
    let(:valid_params) do
      {
        product: {
          name: 'Sony A7 IV Camera',
          description: 'Professional mirrorless camera',
          category: 'Camera',
          barcode: 'CAM-001',
          daily_price_cents: 15000,
          daily_price_currency: 'USD',
          quantity: 3,
          active: true
        }
      }
    end

    context 'with valid params' do
      it 'creates a new product' do
        expect {
          post '/api/v1/products', headers: auth_headers, params: valid_params.to_json
        }.to change(Product, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['product']['name']).to eq('Sony A7 IV Camera')
        expect(json['message']).to eq('Product created successfully')
      end

      it 'assigns product to current company' do
        post '/api/v1/products', headers: auth_headers, params: valid_params.to_json
        json = JSON.parse(response.body)
        created_product = Product.find(json['product']['id'])

        expect(created_product.company_id).to eq(company.id)
      end

      it 'creates rental item by default' do
        post '/api/v1/products', headers: auth_headers, params: valid_params.to_json
        json = JSON.parse(response.body)
        created_product = Product.find(json['product']['id'])

        expect(created_product.item_type_rental?).to be true
      end

      it 'creates sale item when specified' do
        valid_params[:product][:item_type] = 'sale'
        valid_params[:product][:sale_price_cents] = 50000
        valid_params[:product][:sale_price_currency] = 'USD'

        post '/api/v1/products', headers: auth_headers, params: valid_params.to_json
        json = JSON.parse(response.body)
        created_product = Product.find(json['product']['id'])

        expect(created_product.item_type_sale?).to be true
      end

      it 'sets custom fields' do
        valid_params[:product][:custom_fields] = { color: 'black', sensor: '33MP' }
        post '/api/v1/products', headers: auth_headers, params: valid_params.to_json
        json = JSON.parse(response.body)

        expect(json['product']['custom_fields']['color']).to eq('black')
        expect(json['product']['custom_fields']['sensor']).to eq('33MP')
      end
    end

    context 'with invalid params' do
      it 'returns errors when name is missing' do
        valid_params[:product][:name] = ''
        post '/api/v1/products', headers: auth_headers, params: valid_params.to_json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end

      it 'returns errors when quantity is zero or negative' do
        valid_params[:product][:quantity] = 0
        post '/api/v1/products', headers: auth_headers, params: valid_params.to_json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include(a_string_matching(/quantity/i))
      end

      it 'returns errors when price is negative' do
        valid_params[:product][:daily_price_cents] = -100
        post '/api/v1/products', headers: auth_headers, params: valid_params.to_json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end

      it 'returns errors for duplicate barcode' do
        existing = create(:product, barcode: 'UNIQUE-123', company: company)
        valid_params[:product][:barcode] = 'UNIQUE-123'

        post '/api/v1/products', headers: auth_headers, params: valid_params.to_json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include(a_string_matching(/barcode/i))
      end
    end
  end

  describe 'PATCH /api/v1/products/:id' do
    it 'updates product attributes' do
      patch "/api/v1/products/#{product.id}",
        headers: auth_headers,
        params: { product: { name: 'Updated Name', quantity: 10 } }.to_json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['product']['name']).to eq('Updated Name')
      expect(json['product']['quantity']).to eq(10)
      expect(json['message']).to eq('Product updated successfully')

      product.reload
      expect(product.name).to eq('Updated Name')
      expect(product.quantity).to eq(10)
    end

    it 'updates pricing information' do
      patch "/api/v1/products/#{product.id}",
        headers: auth_headers,
        params: { product: { daily_price_cents: 20000, weekly_price_cents: 100000 } }.to_json

      product.reload
      expect(product.daily_price_cents).to eq(20000)
      expect(product.weekly_price_cents).to eq(100000)
    end

    it 'updates custom fields' do
      patch "/api/v1/products/#{product.id}",
        headers: auth_headers,
        params: { product: { custom_fields: { weight: '2kg', dimensions: '10x10x10' } } }.to_json

      product.reload
      expect(product.custom_fields['weight']).to eq('2kg')
      expect(product.custom_fields['dimensions']).to eq('10x10x10')
    end

    it 'returns errors for invalid updates' do
      patch "/api/v1/products/#{product.id}",
        headers: auth_headers,
        params: { product: { quantity: -5 } }.to_json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end

    it 'returns 404 for non-existent product' do
      patch '/api/v1/products/99999',
        headers: auth_headers,
        params: { product: { name: 'Test' } }.to_json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/products/:id' do
    it 'marks product as inactive (soft delete)' do
      delete "/api/v1/products/#{product.id}", headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['message']).to eq('Product archived successfully')

      product.reload
      expect(product.active).to be false
    end

    it 'does not actually delete the record' do
      expect {
        delete "/api/v1/products/#{product.id}", headers: auth_headers
      }.not_to change(Product, :count)
    end

    it 'returns 404 for non-existent product' do
      delete '/api/v1/products/99999', headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/products/:id/availability' do
    let(:start_date) { 5.days.from_now.to_date }
    let(:end_date) { 7.days.from_now.to_date }

    it 'returns availability information for a product' do
      get "/api/v1/products/#{product.id}/availability",
        headers: auth_headers,
        params: { start_date: start_date.to_s, end_date: end_date.to_s }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json['product_id']).to eq(product.id)
      expect(json['product_name']).to eq(product.name)
      expect(json['total_quantity']).to eq(product.quantity)
      expect(json).to have_key('available_quantity')
      expect(json).to have_key('is_available')
      expect(json).to have_key('availability_by_date')
    end

    it 'uses default dates when not provided' do
      get "/api/v1/products/#{product.id}/availability", headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('date_range')
    end

    it 'shows reduced availability when bookings exist' do
      # Create a booking that overlaps with our date range
      booking = create(:booking,
        company: company,
        start_date: start_date,
        end_date: end_date,
        status: :confirmed
      )
      create(:booking_line_item, booking: booking, bookable: product, quantity: 2)

      get "/api/v1/products/#{product.id}/availability",
        headers: auth_headers,
        params: { start_date: start_date.to_s, end_date: end_date.to_s }

      json = JSON.parse(response.body)
      expect(json['available_quantity']).to be < product.quantity
    end

    it 'returns 404 for non-existent product' do
      get '/api/v1/products/99999/availability',
        headers: auth_headers,
        params: { start_date: start_date.to_s, end_date: end_date.to_s }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/products/search_by_barcode/:barcode' do
    it 'finds product by barcode' do
      product.update(barcode: 'BARCODE-123')
      get '/api/v1/products/search_by_barcode/BARCODE-123', headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['found']).to be true
      expect(json['product']['id']).to eq(product.id)
      expect(json['product']['barcode']).to eq('BARCODE-123')
    end

    it 'returns 404 when barcode not found' do
      get '/api/v1/products/search_by_barcode/NONEXISTENT', headers: auth_headers

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['found']).to be false
      expect(json['message']).to include('No product found')
    end

    it 'only searches within current company' do
      other_company = create(:company)
      other_product = create(:product, barcode: 'OTHER-123', company: other_company)

      get '/api/v1/products/search_by_barcode/OTHER-123', headers: auth_headers

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['found']).to be false
    end
  end

  describe 'POST /api/v1/products/:id/transfer' do
    let(:new_location) { create(:location, company: company) }

    it 'transfers product to new location' do
      post "/api/v1/products/#{product.id}/transfer",
        headers: auth_headers,
        params: { location_id: new_location.id }.to_json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['message']).to eq('Product transferred successfully')
      expect(json['transfer']['to']['id']).to eq(new_location.id)

      product.reload
      expect(product.storage_location_id).to eq(new_location.id)
    end

    it 'records previous location in transfer' do
      old_location = create(:location, company: company)
      product.update(storage_location: old_location)

      post "/api/v1/products/#{product.id}/transfer",
        headers: auth_headers,
        params: { location_id: new_location.id }.to_json

      json = JSON.parse(response.body)
      expect(json['transfer']['from']['id']).to eq(old_location.id)
    end

    it 'returns 404 for invalid location' do
      post "/api/v1/products/#{product.id}/transfer",
        headers: auth_headers,
        params: { location_id: 99999 }.to_json

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Location not found')
    end
  end

  describe 'PATCH /api/v1/products/:id/archive' do
    it 'archives the product' do
      patch "/api/v1/products/#{product.id}/archive", headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['message']).to eq('Product archived')
      expect(json['product']['archived']).to be true

      product.reload
      expect(product.archived).to be true
    end
  end

  describe 'PATCH /api/v1/products/:id/unarchive' do
    it 'unarchives the product' do
      product.update(archived: true)
      patch "/api/v1/products/#{product.id}/unarchive", headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['message']).to eq('Product unarchived')
      expect(json['product']['archived']).to be false

      product.reload
      expect(product.archived).to be false
    end
  end

  describe 'Stock management for sale items' do
    let(:sale_product) do
      create(:product,
        company: company,
        item_type: :sale,
        sale_price_cents: 10000,
        sale_price_currency: 'USD',
        tracks_inventory: true,
        stock_on_hand: 100,
        reorder_point: 20
      )
    end

    describe 'POST /api/v1/products/:id/increment_stock' do
      it 'increases stock for sale items' do
        post "/api/v1/products/#{sale_product.id}/increment_stock",
          headers: auth_headers,
          params: { quantity: 50 }.to_json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['message']).to include('Stock increased by 50')
        expect(json['product']['stock_on_hand']).to eq(150)

        sale_product.reload
        expect(sale_product.stock_on_hand).to eq(150)
      end

      it 'returns error for non-sale items' do
        rental_product = create(:product, item_type: :rental, company: company)
        post "/api/v1/products/#{rental_product.id}/increment_stock",
          headers: auth_headers,
          params: { quantity: 10 }.to_json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to include('only available for sale items')
      end

      it 'returns error for invalid quantity' do
        post "/api/v1/products/#{sale_product.id}/increment_stock",
          headers: auth_headers,
          params: { quantity: 0 }.to_json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to include('greater than 0')
      end
    end

    describe 'POST /api/v1/products/:id/decrement_stock' do
      it 'decreases stock for sale items' do
        post "/api/v1/products/#{sale_product.id}/decrement_stock",
          headers: auth_headers,
          params: { quantity: 30 }.to_json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['message']).to include('Stock decreased by 30')
        expect(json['product']['stock_on_hand']).to eq(70)

        sale_product.reload
        expect(sale_product.stock_on_hand).to eq(70)
      end

      it 'returns error when trying to decrease below zero' do
        post "/api/v1/products/#{sale_product.id}/decrement_stock",
          headers: auth_headers,
          params: { quantity: 150 }.to_json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end
    end

    describe 'POST /api/v1/products/:id/restock' do
      it 'sets stock to specific amount' do
        post "/api/v1/products/#{sale_product.id}/restock",
          headers: auth_headers,
          params: { stock_on_hand: 200 }.to_json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['message']).to include('Stock updated from 100 to 200')
        expect(json['product']['stock_on_hand']).to eq(200)

        sale_product.reload
        expect(sale_product.stock_on_hand).to eq(200)
      end

      it 'returns error for negative stock' do
        post "/api/v1/products/#{sale_product.id}/restock",
          headers: auth_headers,
          params: { stock_on_hand: -10 }.to_json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to include('cannot be negative')
      end
    end

    describe 'stock information in product JSON' do
      it 'includes stock information for sale items with inventory tracking' do
        get "/api/v1/products/#{sale_product.id}", headers: auth_headers
        json = JSON.parse(response.body)

        expect(json['product']['stock']).to be_present
        expect(json['product']['stock']['on_hand']).to eq(100)
        expect(json['product']['stock']['reorder_point']).to eq(20)
        expect(json['product']['stock']).to have_key('out_of_stock')
        expect(json['product']['stock']).to have_key('low_stock')
      end

      it 'includes sale price for sale items' do
        get "/api/v1/products/#{sale_product.id}", headers: auth_headers
        json = JSON.parse(response.body)

        expect(json['product']['sale_price']).to be_present
        expect(json['product']['sale_price']['amount']).to eq(10000)
        expect(json['product']['sale_price']['formatted']).to be_present
      end
    end
  end

  describe 'Multi-tenancy' do
    it 'only returns products for current company' do
      other_company = create(:company)
      other_products = create_list(:product, 3, company: other_company)

      get '/api/v1/products', headers: auth_headers
      json = JSON.parse(response.body)
      product_ids = json['products'].map { |p| p['id'] }

      expect(product_ids).not_to include(*other_products.map(&:id))
      expect(product_ids).to match_array(products.map(&:id))
    end

    it 'returns 404 when trying to access another company\'s product' do
      other_company = create(:company)
      other_product = create(:product, company: other_company)

      get "/api/v1/products/#{other_product.id}", headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'Authentication' do
    it 'requires authentication token' do
      get '/api/v1/products'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects invalid tokens' do
      get '/api/v1/products', headers: { 'Authorization' => 'Bearer invalid-token' }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
