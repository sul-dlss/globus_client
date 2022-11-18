# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require "faraday"
require "ostruct"
require "singleton"
require "zeitwerk"

# Load the gem's internal dependencies
loader = Zeitwerk::Loader.new
loader.inflector = Zeitwerk::GemInflector.new(__FILE__)
loader.push_dir(File.absolute_path("#{__FILE__}/../.."))
loader.setup

module Globus
  # Client for interacting with the Globus API
  class Client
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
          token: Globus::Client::Authenticator.token(client_id, client_secret, auth_url),
          uploads_directory:,
          transfer_endpoint_id:,
          transfer_url:,
          auth_url:
        )

        self
      end

      delegate :mkdir, :config, to: :instance

      def default_transfer_url
        "https://transfer.api.globusonline.org"
      end

      def default_auth_url
        "https://auth.globus.org"
      end
    end

    attr_accessor :config

    def mkdir(...)
      endpoint = Globus::Client::Endpoint.new(config, ...)
      endpoint.mkdir
      endpoint.set_permissions
    end
  end
end
