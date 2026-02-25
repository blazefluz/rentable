require 'rails_helper'

RSpec.describe "Api::V1::InsuranceCertificates", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/insurance_certificates/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/insurance_certificates/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/insurance_certificates/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/insurance_certificates/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/insurance_certificates/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
