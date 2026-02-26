require 'rails_helper'

RSpec.describe "Api::V1::ProductCollections", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/product_collections/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/product_collections/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/product_collections/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/product_collections/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/product_collections/destroy"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /add_product" do
    it "returns http success" do
      get "/api/v1/product_collections/add_product"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /remove_product" do
    it "returns http success" do
      get "/api/v1/product_collections/remove_product"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /reorder" do
    it "returns http success" do
      get "/api/v1/product_collections/reorder"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /featured" do
    it "returns http success" do
      get "/api/v1/product_collections/featured"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /analytics" do
    it "returns http success" do
      get "/api/v1/product_collections/analytics"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /refresh" do
    it "returns http success" do
      get "/api/v1/product_collections/refresh"
      expect(response).to have_http_status(:success)
    end
  end

end
