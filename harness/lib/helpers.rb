# frozen_string_literal: true

module Helpers
  # Use the response hash as a container for the fields a Provider includes in their responses.
  # Create custom methods to build the format of the response for a given endpoint and use the response hash to fill in the values.
  def reset_response
    $response = {
      "delay_seconds" => 0,
      "error_type" => nil,
      "action" => nil
    }
  end

  def perform_configure
    $response.merge!(params)
    logger.info("Custom Response set with #{params}")
    json($response)
  end

  # This is an example of a custom method that builds the response for a provider endpoint.
  # This method can be used in the Harness within the corresponding endpoint.
  def transaction_response
    logger.info "Params: #{params.inspect}"
    custom_response = {}
    json(custom_response)
  end

  # This allows us to configure a delay before the harness responds back which
  # help us test timeouts or stress scenarios.
  # By default there is no delay but it can be configured by calling the
  # configuration endoint like so: configure/set?delay_seconds=60
  def with_delay
    delay_seconds = Float($response.fetch(:delay_seconds, 0))
    return yield unless delay_seconds.positive?

    logger.info("Waiting: #{delay_seconds} seconds.")

    # Splits the amount in fractions so that we can see some feedback in the logs
    fraction_scale = 10
    fraction_sleep = delay_seconds / fraction_scale
    logger.info("Sleeping for: #{fraction_sleep}")

    fraction_scale.times do |counter|
      remaining = (delay_seconds - (fraction_sleep * counter)).round(2)
      logger.info("Remaining #{remaining} seconds")
      sleep(fraction_sleep)
    end

    yield
  end

  def error_response(type); end
end
