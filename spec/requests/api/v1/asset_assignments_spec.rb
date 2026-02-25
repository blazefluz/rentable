require 'rails_helper'

RSpec.describe "Api::V1::AssetAssignments", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/asset_assignments/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/asset_assignments/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/asset_assignments/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/asset_assignments/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/asset_assignments/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
