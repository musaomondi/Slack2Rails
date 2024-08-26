#!/usr/bin/env ruby

require 'json'
require 'open-uri'
require 'net/http'
require 'fileutils'

# Constants
JSON_FILE = 'spec/support/deprecation_warning.shitlist.json'
GITHUB_API = 'https://api.github.com'
GITHUB_TOKEN = ENV.fetch('GITHUB_TOKEN', nil)
REPO_URL = ENV['CODEBUILD_SOURCE_REPO_URL'].sub('.git', '')
BRANCH = ENV['CODEBUILD_WEBHOOK_HEAD_REF'].sub('refs/heads/', '')

def retrieve_deprecation_warnings
  return unless system('bundle exec deprecations info >/dev/null 2>&1')

  puts 'Deprecation warning found!'

  data = JSON.parse(File.read(JSON_FILE))

  restructured_data = {}

  data.each do |file, warnings|
    warnings.each do |warning|
      # Initialize an empty array if the warning is encountered for the first time
      restructured_data[warning] ||= []
      # Append the file if it's not already included
      restructured_data[warning] << file unless restructured_data[warning].include?(file)
    end
  end

  restructured_data
end

def generate_markdown_output(warnings_data)
  output = warnings_data.map do |warning, files|
    file_links = files.map { |file| generate_file_link(file) }.join("\n\n")
    <<~LIST_ITEM
      <li>#{warning}
        <details><summary>Click to see affected specs:</summary>
        <ol>#{file_links}</ol></details>
      </li>
    LIST_ITEM
  end.join("\n\n")

  <<~MARKDOWN
    ## Deprecation Warnings

    <ol>#{output}</ol>
  MARKDOWN
end

def generate_file_link(file)
  file_path = file.sub('./', '')
  "<li><a href=\"#{REPO_URL}/blob/#{BRANCH}/#{file_path}\">#{file_path}</a></li>"
end

def post_github_comment(pr_number, markdown_output)
  repo_name = REPO_URL.sub(%r{^https://github.com/}, '')
  base_comments_url = "#{GITHUB_API}/repos/#{repo_name}/issues"
  comments_url = "#{base_comments_url}/#{pr_number}/comments"
  existing_comment_id = find_existing_comment(comments_url)

  if existing_comment_id
    update_comment(base_comments_url, existing_comment_id, markdown_output)
  else
    create_comment(comments_url, markdown_output)
  end
end

def find_existing_comment(comments_url)
  url = "#{comments_url}?q=Deprecation Warnings"
  response = send_github_api_request(url, 'GET')

  return nil unless response.code == '200'

  comments = JSON.parse(response.body)
  matching_comment = comments.find { |comment| comment['body']&.include?('## Deprecation Warnings') }
  matching_comment['id'] if matching_comment
end

def create_comment(comments_url, markdown_output)
  payload = { 'body' => markdown_output }.to_json
  send_github_api_request(comments_url, 'POST', payload)
end

def update_comment(comments_url, comment_id, markdown_output)
  url = "#{comments_url}/comments/#{comment_id}"
  payload = { 'body' => markdown_output }.to_json
  send_github_api_request(url, 'PATCH', payload)
end

def send_github_api_request(url, method, payload = nil)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = case method
            when 'GET' then Net::HTTP::Get.new(uri)
            when 'POST' then Net::HTTP::Post.new(uri)
            when 'PATCH' then Net::HTTP::Patch.new(uri)
            end

  request['Authorization'] = "token #{GITHUB_TOKEN}"
  request['Content-Type'] = 'application/json'
  request.body = payload if payload

  http.request(request)
end

def retrieve_pull_request_number
  url = "#{GITHUB_API}/search/issues?q=sha:#{ENV.fetch('GIT_COMMIT', nil)}"
  response = send_github_api_request(url, 'GET')

  return nil unless response.code == '200'

  pr_number = JSON.parse(response.body)['items']&.first&.[]('number')
  pr_number&.to_s
end

def main
  puts 'Checking for deprecation warnings'

  warnings_data = retrieve_deprecation_warnings

  if !warnings_data || warnings_data.empty?
    puts 'No test files with deprecation warning.'
    markdown_output =   <<~MARKDOWN
      ## Deprecation Warnings

      No deprecation warning found.
    MARKDOWN
  else
   markdown_output = generate_markdown_output(warnings_data)
  end
  
  pr_number = retrieve_pull_request_number
  post_github_comment(pr_number, markdown_output)

  FileUtils.rm_f(JSON_FILE)
  system('git restore Gem*')
end

main
