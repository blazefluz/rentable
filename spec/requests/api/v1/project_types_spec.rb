require 'rails_helper'

RSpec.describe "Api::V1::ProjectTypes", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/project_types/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/project_types/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/project_types/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/project_types/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/project_types/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
