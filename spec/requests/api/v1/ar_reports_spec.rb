require 'rails_helper'

RSpec.describe "Api::V1::ArReports", type: :request do
  describe "GET /aging" do
    it "returns http success" do
      get "/api/v1/ar_reports/aging"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /summary" do
    it "returns http success" do
      get "/api/v1/ar_reports/summary"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /by_client" do
    it "returns http success" do
      get "/api/v1/ar_reports/by_client"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /overdue_list" do
    it "returns http success" do
      get "/api/v1/ar_reports/overdue_list"
      expect(response).to have_http_status(:success)
    end
  end

end
