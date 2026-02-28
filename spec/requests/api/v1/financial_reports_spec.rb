require 'rails_helper'

RSpec.describe "Api::V1::FinancialReports", type: :request do
  describe "GET /profit_loss" do
    it "returns http success" do
      get "/api/v1/financial_reports/profit_loss"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /revenue_breakdown" do
    it "returns http success" do
      get "/api/v1/financial_reports/revenue_breakdown"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /expense_summary" do
    it "returns http success" do
      get "/api/v1/financial_reports/expense_summary"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /roi_analysis" do
    it "returns http success" do
      get "/api/v1/financial_reports/roi_analysis"
      expect(response).to have_http_status(:success)
    end
  end

end
