require 'rails_helper'

RSpec.describe "Api::V1::Deliveries", type: :request do
  describe "GET /schedule" do
    it "returns http success" do
      get "/api/v1/deliveries/schedule"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update_status" do
    it "returns http success" do
      get "/api/v1/deliveries/update_status"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /mark_delivered" do
    it "returns http success" do
      get "/api/v1/deliveries/mark_delivered"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /mark_failed" do
    it "returns http success" do
      get "/api/v1/deliveries/mark_failed"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /cancel" do
    it "returns http success" do
      get "/api/v1/deliveries/cancel"
      expect(response).to have_http_status(:success)
    end
  end

end
