require 'rails_helper'

RSpec.describe "Api::V1::QrCodes", type: :request do
  describe "GET /generate" do
    it "returns http success" do
      get "/api/v1/qr_codes/generate"
      expect(response).to have_http_status(:success)
    end
  end

end
