require 'rails_helper'

RSpec.describe "Api::V1::PricingRules", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/pricing_rules/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/pricing_rules/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/pricing_rules/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/pricing_rules/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/pricing_rules/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
