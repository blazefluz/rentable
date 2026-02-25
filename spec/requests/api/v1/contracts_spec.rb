require 'rails_helper'

RSpec.describe "Api::V1::Contracts", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/contracts/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/contracts/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/contracts/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/contracts/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/contracts/destroy"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /sign" do
    it "returns http success" do
      get "/api/v1/contracts/sign"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /request_signature" do
    it "returns http success" do
      get "/api/v1/contracts/request_signature"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /generate_pdf" do
    it "returns http success" do
      get "/api/v1/contracts/generate_pdf"
      expect(response).to have_http_status(:success)
    end
  end

end
