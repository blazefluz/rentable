require 'rails_helper'

RSpec.describe "Api::V1::ClientCommunications", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/client_communications/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/client_communications/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/client_communications/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/client_communications/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/client_communications/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
