require 'rails_helper'

RSpec.describe "Api::V1::AssetGroups", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/asset_groups/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/asset_groups/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/asset_groups/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/asset_groups/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/asset_groups/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
