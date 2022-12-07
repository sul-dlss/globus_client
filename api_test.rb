#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "globus_client"

GlobusClient.configure(
  client_id: ENV["GLOBUS_CLIENT_ID"],
  client_secret: ENV["GLOBUS_CLIENT_SECRET"],
  uploads_directory: ENV["GLOBUS_UPLOADS_DIRECTORY"],
  transfer_endpoint_id: ENV["GLOBUS_ENDPOINT"]
)

user_id, work_id, work_version = *ARGV

# Test public API methods here.
GlobusClient.mkdir(user_id:, work_id:, work_version:)

user_exists = GlobusClient.user_exists?(user_id)

# Not part of the public API but this allows us to test access changes
before_permissions = GlobusClient::Endpoint.new(GlobusClient.config, user_id: user_id, work_id: work_id, work_version: work_version).send(:access_rule)["permissions"]

files_count = GlobusClient.file_count(user_id:, work_id:, work_version:)

total_size = GlobusClient.total_size(user_id:, work_id:, work_version:)

GlobusClient.disallow_writes(user_id:, work_id:, work_version:)

# Not part of the public API but this allows us to test access changes
after_permissions = GlobusClient::Endpoint.new(GlobusClient.config, user_id: user_id, work_id: work_id, work_version: work_version).send(:access_rule)["permissions"]

puts "User #{user_id} exists: #{user_exists}"
puts "Initial directory permissions: #{before_permissions}"
puts "Number of files in directory: #{files_count}"
puts "Total size of files in directory: #{total_size}"
puts "Final directory permissions: #{after_permissions}"
