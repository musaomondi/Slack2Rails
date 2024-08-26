# LiquidityRequest Harness

This Sinatra project will run a local server mimicking the functionality of the LiquidityRequest API endpoints.

This is a rack project, so to start the local server run `bundle exec rackup`.

To assist testing it also provides the following helper endpoints to set/reset the response:

GET `/configure/reset`: Resets all changes back to the default values.
GET `/configure/set?`: Sets the response parameters for the next call.

- `delay_seconds=`
- `action=`
- `error_type=`

## Endpoints

GET `/configure/set?action=check&error_type=XYZ`: You can use the XYZ error tpye to simulate an error only on the check action. The error type is ignored for all other actions. To use the error for all actions, omit the action parameter.

GET `/healthcheck` ==> Check that the harness is up and running
