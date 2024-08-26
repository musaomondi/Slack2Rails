# frozen_string_literal: true

say <<~INFO
  Generating a new Rails Template with the following variables.

  Backstage Variables:

  name: liquidity-request
  kebabCase: liquidity-request
  pascalCase: LiquidityRequest
  camelCase: liquidityRequest
  snakeCase: liquidity_request
  pascalKebabCase: Liquidity-Request
  repoOwner: bitpesa
  api: false
  active_job: false
  asset_pipeline: sprockets
  javascript: importmap
  hotwire: false
  css_processor: sass
  db: postgresql
  harness: false

  Rails Generator options:

  #{options.map { |option, value| "#{option} => #{value}\n" }.join}

  These are for debugging purposes.
INFO

say_status :readme, "Remove help text in README"
gsub_file "README.md", /<!--TO_BE_REMOVED-->.*<!--TO_BE_REMOVED-->\n+/m, ""

say_status :harness, "Check if harness should be included. (Harness - false)"
if "false".casecmp("true").zero?
  say "Remove harness as it's not selected"
  remove_dir "harness"
  remove_file ".github/workflows/harness-deployment.yaml"
else
  say "Harness not removed as it's included"
end

say_status :health_check, "create spec folder"
run "mkdir -p spec"

file "spec/requests/health_check_spec.rb", <<~CODE
  require 'rails_helper'

  RSpec.describe "HealthCheck", type: :request do
    describe "GET /" do
      it "returns http success" do
        get "/healthcheck"
        expect(response).to have_http_status(:success)
      end
    end
  end

CODE

file "spec/routing/health_check_routing_spec.rb", <<~CODE
  require "rails_helper"

  RSpec.describe HealthCheckController, type: :routing do
    describe "routing" do
      it "routes to #index" do
        expect(get: "/healthcheck").to route_to("health_check#index")
      end
    end
  end
CODE

say_status :health_check, "create health_check route"
route "get '/healthcheck', to: 'health_check#index'"

say_status :health_check, "Create healthcheck lib"
inside("app") do
  run "mkdir -p lib"
  run "mkdir -p lib/health_check"
end

if skip_active_record?
  say_status :health_check, "Creating healthcheck with DB (skipped Active Record)"
  file "app/controllers/health_check_controller.rb", <<~CODE
    # frozen_string_literal: true

    class HealthCheckController < ApplicationController
      def index
        render json: { status: true }
      end
    end
  CODE
else
  file "app/controllers/health_check_controller.rb", <<~CODE
    # frozen_string_literal: true

    class HealthCheckController < ApplicationController
      def index
        results = HealthCheck::Database.new.check
        all_pass = HealthCheck::Database.all_pass?(results)
        render json: { results: results, status: all_pass ? :ok : :internal_server_error }
      end
    end

  CODE

  file "app/lib/health_check/database.rb", <<~CODE
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
  CODE

  file "app/lib/health_check/helper.rb", <<~CODE
    # frozen_string_literal: true

    module HealthCheck
      module Helper
        def run_check(name)
          results = {
            kind: self.class.to_s,
            name: name,
            pass: false,
          }
          begin
            results[:pass] = yield
          rescue StandardError => e
            results[:message] = "\#{e.class}: \#{e.message}"
          end
          results
        end
      end
    end
  CODE
end

match_development_test_gem_group = nil
gsub_file "Gemfile", "\ngroup :development, :test do", force: true do |match|
  say_status :in_gemfile, "Add to existing gems for dev and test group"
  match_development_test_gem_group = match
  <<~GEM
    group :development, :test do
      gem 'brakeman', require: false
      gem 'bundle-audit', require: false
      gem 'pry'
      gem 'rubocop', require: false
      gem 'rubocop-rails', require: false
      gem 'rubocop-rake', require: false
      gem 'rubocop-rspec', require: false
      gem 'rubocop-performance', require: false
      gem 'rubocop-thread_safety', require: false
      gem 'rspec'
      gem 'rspec-rails'
  GEM
end

unless match_development_test_gem_group
  say_status :in_gemfile, "Add new entry for dev and test gems"
  gem_group :development, :test do
    gem "brakeman", require: false
    gem "bundle-audit", require: false
    gem "pry"
    gem "rubocop", require: false
    gem "rubocop-rails", require: false
    gem "rubocop-rake", require: false
    gem "rubocop-rspec", require: false
    gem "rubocop-performance", require: false
    gem "rubocop-thread_safety", require: false
    gem "rspec"
    gem "rspec-rails"
  end
end

say_status :aza_seim, "Add aza-seim only on bitpesa repo"
if "bitpesa".match?(/^bitpesa$/)
  say_status :aza_seim, "create aza-siem initializer"
  initializer "datadog.rb", <<~CODE
    # frozen_string_literal: true

    Datadog.configure do |config|
      AzaSIEM::DatadogConfig.call(config)
    end
  CODE

  say_status :aza_seim, "Add aza-siem to environment"
  environment "AzaSIEM::RailsLoggingConfig.call(config)"
  gem "aza-siem",
      git: "git@github.com:bitpesa/aza-siem.git",
      comment: "aza-siem must be last gem to load in order to detect dependencies and let dotenv load ENVs"
end

say_status :in_gemfile, "Remove Ruby version specification from the Gemfile"
gsub_file "Gemfile", /ruby (".*"|'.*')/, ""

bundle_command "lock --add-platform=aarch64-linux"

after_bundle do
  generate "rspec:install"
  run "bundle exec rubocop --display-only-fail-level-offenses -A || true"
end
