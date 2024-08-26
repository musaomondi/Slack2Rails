# Base
require "bundler/setup"
require "sinatra/base"
require "sinatra/json"
require "securerandom"
require "rack/contrib/json_body_parser"
require "pry"
require "dotenv"

Dotenv.load

# Logging
require "logger"
require "ddtrace/auto_instrument"
require "aza-siem"
require "./config/initializers/datadog"

# Harness specifics
require "./lib/helpers"
require "./lib/harness"
