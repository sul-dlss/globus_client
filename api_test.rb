#!/usr/bin/env ruby
# frozen_string_literal: true

require "benchmark"
require "bundler/setup"
require "globus_client"

Benchmark.bm(20) do |benchmark|
  user_id, path = *ARGV

  benchmark.report("Configure:") do
    GlobusClient.configure(
      client_id: ENV["GLOBUS_CLIENT_ID"],
      client_secret: ENV["GLOBUS_CLIENT_SECRET"],
      uploads_directory: ENV["GLOBUS_UPLOADS_DIRECTORY"],
      transfer_endpoint_id: ENV["GLOBUS_ENDPOINT"]
    )
  end

  benchmark.report("mkdir:") do
    GlobusClient.mkdir(user_id:, path:)
  end

  benchmark.report("user_valid?:") do
    @user_exists = GlobusClient.user_valid?(user_id)
  end

  benchmark.report("before_perms:") do
    # Not part of the public API but this allows us to test access changes
    @before_permissions = GlobusClient::Endpoint.new(GlobusClient.config, user_id:, path:).send(:access_rule)["permissions"]
  end

  benchmark.report("has_files?:") do
    @has_files = GlobusClient.has_files?(user_id:, path:)
  end

  benchmark.report("list_files:") do
    GlobusClient.list_files(user_id:, path:) do |files|
      @files_count = files.count
      @total_size = files.sum(&:size)
      @files_list = files.map(&:name)
    end
  end

  benchmark.report("disallow_writes:") do
    GlobusClient.disallow_writes(user_id:, path:)
  end

  benchmark.report("after_perms:") do
    # Not part of the public API but this allows us to test access changes
    @after_permissions = GlobusClient::Endpoint.new(GlobusClient.config, user_id:, path:).send(:access_rule)["permissions"]
  end

  puts "User #{user_id} exists: #{@user_exists}"
  puts "Initial directory permissions: #{@before_permissions}"
  puts "Directory has files? #{@has_files}"
  puts "Number of files in directory: #{@files_count}"
  puts "Total size of files in directory: #{@total_size}"
  puts "List of files in directory: #{@files_list}"
  puts "Final directory permissions: #{@after_permissions}"
end
