require 'rails_helper'

RSpec.describe "Api::V1::Leads", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/leads/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/leads/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/leads/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/leads/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/leads/destroy"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /convert" do
    it "returns http success" do
      get "/api/v1/leads/convert"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /mark_lost" do
    it "returns http success" do
      get "/api/v1/leads/mark_lost"
      expect(response).to have_http_status(:success)
    end
  end

end
