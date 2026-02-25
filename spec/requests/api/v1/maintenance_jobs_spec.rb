require 'rails_helper'

RSpec.describe "Api::V1::MaintenanceJobs", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/maintenance_jobs/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/maintenance_jobs/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/maintenance_jobs/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/maintenance_jobs/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/maintenance_jobs/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
