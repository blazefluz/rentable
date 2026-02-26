require 'rails_helper'

RSpec.describe "Api::V1::TaxRates", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/tax_rates/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/tax_rates/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/tax_rates/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/tax_rates/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/tax_rates/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
