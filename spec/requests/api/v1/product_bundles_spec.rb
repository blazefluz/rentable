require 'rails_helper'

RSpec.describe "Api::V1::ProductBundles", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/product_bundles/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/product_bundles/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/product_bundles/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/product_bundles/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/product_bundles/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
