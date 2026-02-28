require 'rails_helper'

RSpec.describe "Api::V1::Expenses", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/expenses/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/expenses/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/expenses/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/expenses/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/expenses/destroy"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /summary" do
    it "returns http success" do
      get "/api/v1/expenses/summary"
      expect(response).to have_http_status(:success)
    end
  end

end
