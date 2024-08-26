# frozen_string_literal: true

require "rails_helper"

RSpec.describe HealthCheckController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/healthcheck").to route_to("health_check#index")
    end
  end
end
