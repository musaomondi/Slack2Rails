# frozen_string_literal: true

class HealthCheckController < ApplicationController
  def index
    results = HealthCheck::Database.new.check
    all_pass = HealthCheck::Database.all_pass?(results)
    render json: { results:, status: all_pass ? :ok : :internal_server_error }
  end
end
