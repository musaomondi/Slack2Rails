# frozen_string_literal: true

Datadog.configure do |config|
  AzaSIEM::DatadogConfig.call(config)
end
