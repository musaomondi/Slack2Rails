# frozen_string_literal: true

module HealthCheck
  class Database
    include Helper

    def check
      [
        run_check("db.connection") do
          ActiveRecord::Base.connected?
        end
      ]
    end

    def self.all_pass?(results)
      results.all? { |result| result[:pass] == true }
    end
  end
end
