require 'rails_helper'

RSpec.describe "Api::V1::Catalogs", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/catalog/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /featured" do
    it "returns http success" do
      get "/api/v1/catalog/featured"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /popular" do
    it "returns http success" do
      get "/api/v1/catalog/popular"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /search" do
    it "returns http success" do
      get "/api/v1/catalog/search"
      expect(response).to have_http_status(:success)
    end
  end

end
