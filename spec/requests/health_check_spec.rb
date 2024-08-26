# frozen_string_literal: true

require "rails_helper"

RSpec.describe "HealthCheck", type: :request do
  describe "GET /" do
    it "returns http success" do
      get "/healthcheck"
      expect(response).to have_http_status(:success)
    end
  end
end
