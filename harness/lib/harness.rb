# frozen_string_literal: true

include Helpers

reset_response

class LiquidityRequestHarness < Sinatra::Base
  configure do
    enable :logging
  end

  register Datadog::Tracing::Contrib::Sinatra::Tracer
  use ::AzaSIEM::SinatraLoggingConfig::Logger
  use ::AzaSIEM::SinatraLoggingConfig::RequestLogger
  use Rack::JSONBodyParser

  get "/healthcheck" do
    logger.info("Harness is up and healthy!")
    json({ healthcheck: true })
  end

  # response can have three keys: error_type, action, delay_seconds
  post "/configure/set" do
    perform_configure
  end

  get "/configure/reset" do
    reset_response
    logger.info("Custom Response was reset!")
    json($response)
  end
end
