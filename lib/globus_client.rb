# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require "faraday"
require "faraday/retry"
require "ostruct"
require "singleton"
require "zeitwerk"

# Load the gem's internal dependencies: use Zeitwerk instead of needing to manually require classes
Zeitwerk::Loader.for_gem.setup

# Client for interacting with the Globus API
class GlobusClient
  include Singleton

  class << self
    # @param client_id [String] the client identifier registered with Globus
    # @param client_secret [String] the client secret to authenticate with Globus
    # @param uploads_directory [String] where to upload files
    # @param transfer_endpoint_id [String] the transfer API endpoint ID supplied by Globus
    # @param transfer_url [String] the transfer API URL
    # @param auth_url [String] the authentication API URL
    def configure(client_id:, client_secret:, uploads_directory:, transfer_endpoint_id:, transfer_url: default_transfer_url, auth_url: default_auth_url)
      instance.config = OpenStruct.new(
        token: Authenticator.token(client_id, client_secret, auth_url),
        client_id:,
        client_secret:,
        uploads_directory:,
        transfer_endpoint_id:,
        transfer_url:,
        auth_url:
      )

      self
    end

    delegate :config, :disallow_writes, :file_count, :list_files, :mkdir, :total_size,
      :user_valid?, :get_filenames, :has_files?, to: :instance

    def default_transfer_url
      "https://transfer.api.globusonline.org"
    end

    def default_auth_url
      "https://auth.globus.org"
    end
  end

  attr_accessor :config

  def mkdir(...)
    TokenWrapper.refresh(config) do
      endpoint = Endpoint.new(config, ...)
      endpoint.mkdir
      endpoint.allow_writes
    end
  end

  def disallow_writes(...)
    TokenWrapper.refresh(config) do
      endpoint = Endpoint.new(config, ...)
      endpoint.disallow_writes
    end
  end

  # NOTE: Can't use the `...` (argument forwarding) operator here because we
  #       want to route the keyword args to `Endpoint#new` and the block arg to
  #       `Endpoint#list_files`
  def list_files(**keywords, &block)
    TokenWrapper.refresh(config) do
      endpoint = Endpoint.new(config, **keywords)
      endpoint.list_files(&block)
    end
  end

  def file_count(...)
    TokenWrapper.refresh(config) do
      endpoint = Endpoint.new(config, ...)
      endpoint.list_files { |files| return files.count }
    end
  end

  def total_size(...)
    TokenWrapper.refresh(config) do
      endpoint = Endpoint.new(config, ...)
      endpoint.list_files { |files| return files.sum(&:size) }
    end
  end

  def get_filenames(...)
    TokenWrapper.refresh(config) do
      endpoint = Endpoint.new(config, ...)
      endpoint.list_files { |files| return files.map(&:name) }
    end
  end

  def has_files?(...)
    TokenWrapper.refresh(config) do
      endpoint = Endpoint.new(config, ...)
      endpoint.has_files?
    end
  end

  def user_valid?(...)
    TokenWrapper.refresh(config) do
      identity = Identity.new(config)
      identity.valid?(...)
    end
  end
end
