Datadog.configure do |config|
  AzaSIEM::DatadogConfig.call(config, framework: :sinatra)
end
