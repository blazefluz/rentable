require 'rails_helper'

RSpec.describe "Api::V1::ProductInstances", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/product_instances/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/product_instances/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/product_instances/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/product_instances/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/product_instances/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
