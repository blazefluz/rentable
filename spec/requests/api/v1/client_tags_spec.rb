require 'rails_helper'

RSpec.describe "Api::V1::ClientTags", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/client_tags/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/client_tags/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/client_tags/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/client_tags/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/client_tags/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
