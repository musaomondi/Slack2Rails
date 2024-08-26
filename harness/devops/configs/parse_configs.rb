require "dotenv"

# Parses the files decrypts and writes to file that is used in building a configmap
def build_config_map(environment)
  parsed_configs = Dotenv.parse("#{environment}.env.template")
  config_map = File.open("harness-liquidity-request-service-#{environment}", "w")
  parsed_configs.each do |k, v|
    config_map.puts "#{k}=#{v.delete_prefix('"').delete_suffix('"')}"
  end
  config_map.close
end

if ARGV.empty?
  puts "We are missing the environment"
  exit 1
end

environment = ARGV[0]

if %w[staging sandbox].include?(environment)
  build_config_map(environment)
else
  exit 1
end
