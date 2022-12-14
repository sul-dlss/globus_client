# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require "faraday"
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
        uploads_directory:,
        transfer_endpoint_id:,
        transfer_url:,
        auth_url:
      )

      self
    end

    delegate :config, :disallow_writes, :file_count, :mkdir, :total_size, :user_exists?, :get_filenames, to: :instance

    def default_transfer_url
      "https://transfer.api.globusonline.org"
    end

    def default_auth_url
      "https://auth.globus.org"
    end
  end

  attr_accessor :config

  def mkdir(...)
    endpoint = Endpoint.new(config, ...)
    endpoint.mkdir
    endpoint.allow_writes
  end

  def disallow_writes(...)
    endpoint = Endpoint.new(config, ...)
    endpoint.disallow_writes
  end

  def file_count(...)
    endpoint = Endpoint.new(config, ...)
    endpoint.file_count
  end

  def total_size(...)
    endpoint = Endpoint.new(config, ...)
    endpoint.total_size
  end

  def get_filenames(...)
    endpoint = Endpoint.new(config, ...)
    endpoint.get_filenames
  end

  def user_exists?(...)
    identity = Identity.new(config)
    identity.exists?(...)
  end
end
