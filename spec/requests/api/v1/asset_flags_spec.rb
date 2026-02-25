require 'rails_helper'

RSpec.describe "Api::V1::AssetFlags", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/asset_flags/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/asset_flags/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/asset_flags/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/asset_flags/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/asset_flags/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
