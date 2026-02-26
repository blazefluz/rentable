require 'rails_helper'

RSpec.describe "Api::V1::Companies", type: :request do
  describe "GET /signup" do
    it "returns http success" do
      get "/api/v1/companies/signup"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/companies/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /check_subdomain" do
    it "returns http success" do
      get "/api/v1/companies/check_subdomain"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/companies/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/companies/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /settings" do
    it "returns http success" do
      get "/api/v1/companies/settings"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /branding" do
    it "returns http success" do
      get "/api/v1/companies/branding"
      expect(response).to have_http_status(:success)
    end
  end

end
