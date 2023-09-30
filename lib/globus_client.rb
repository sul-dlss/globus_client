# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'faraday'
require 'faraday/retry'
require 'singleton'
require 'zeitwerk'

# Load the gem's internal dependencies: use Zeitwerk instead of needing to manually require classes
Zeitwerk::Loader.for_gem.setup

# Client for interacting with the Globus API
class GlobusClient # rubocop:disable Metrics/ClassLength
  include Singleton

  class << self
    # @param client_id [String] the client identifier registered with Globus
    # @param client_secret [String] the client secret to authenticate with Globus
    # @param uploads_directory [String] where to upload files
    # @param transfer_endpoint_id [String] the transfer API endpoint ID supplied by Globus
    # @param transfer_url [String] the transfer API URL
    # @param auth_url [String] the authentication API URL
    # rubocop:disable Metrics/ParameterLists
    def configure(client_id:, client_secret:, uploads_directory:, transfer_endpoint_id:,
                  transfer_url: default_transfer_url, auth_url: default_auth_url)
      instance.config = Config.new(
        # For the initial token, use a dummy value to avoid hitting any APIs
        # during configuration, allowing `with_token_refresh_when_unauthorized` to handle
        # auto-magic token refreshing. Why not immediately get a valid token? Our apps
        # commonly invoke client `.configure` methods in the initializer in all
        # application environments, even those that are never expected to
        # connect to production APIs, such as local development machines.
        #
        # NOTE: `nil` and blank string cannot be used as dummy values here as
        # they lead to a malformed request to be sent, which triggers an
        # exception not rescued by `with_token_refresh_when_unauthorized`
        token: 'a temporary dummy token to avoid hitting the API before it is needed',
        client_id:,
        client_secret:,
        uploads_directory:,
        transfer_endpoint_id:,
        transfer_url:,
        auth_url:
      )

      self
    end
    # rubocop:enable Metrics/ParameterLists

    delegate :config, :disallow_writes, :delete_access_rule, :file_count, :list_files, :mkdir, :total_size,
             :user_valid?, :get_filenames, :has_files?, :delete, :get, :post, :put, to: :instance

    def default_transfer_url
      'https://transfer.api.globusonline.org'
    end

    def default_auth_url
      'https://auth.globus.org'
    end
  end

  attr_accessor :config

  # Send an authenticated GET request
  # @param base_url [String] the base URL of the Globus API
  # @param path [String] the path to the Globus API request
  # @param params [Hash] params to get to the API
  def get(base_url:, path:, params: {}, content_type: nil)
    response = with_token_refresh_when_unauthorized do
      connection(base_url).get(path, params) do |request|
        request.headers['Authorization'] = "Bearer #{config.token}"
        request.headers['Content-Type'] = content_type if content_type
      end
    end

    UnexpectedResponse.call(response) unless response.success?

    return nil if response.body.blank?

    JSON.parse(response.body)
  end

  # Send an authenticated POST request
  # @param base_url [String] the base URL of the Globus API
  # @param path [String] the path to the Globus API request
  # @param body [String] the body of the Globus API request
  # @param expected_response [#call] an expected response handler to allow short-circuiting the unexpected response
  def post(base_url:, path:, body:, expected_response: ->(_resp) { false })
    response = with_token_refresh_when_unauthorized do
      connection(base_url).post(path) do |request|
        request.headers['Authorization'] = "Bearer #{config.token}"
        request.headers['Content-Type'] = 'application/json'
        request.body = body.to_json
      end
    end

    UnexpectedResponse.call(response) unless response.success? || expected_response.call(response)

    return nil if response.body.blank?

    JSON.parse(response.body)
  end

  # Send an authenticated PUT request
  # @param base_url [String] the base URL of the Globus API
  # @param path [String] the path to the Globus API request
  # @param body [String] the body of the Globus API request
  def put(base_url:, path:, body:)
    response = with_token_refresh_when_unauthorized do
      connection(base_url).put(path) do |request|
        request.headers['Authorization'] = "Bearer #{config.token}"
        request.headers['Content-Type'] = 'application/json'
        request.body = body.to_json
      end
    end

    UnexpectedResponse.call(response) unless response.success?

    return nil if response.body.blank?

    JSON.parse(response.body)
  end

  # Send an authenticated DELETE request
  # @param base_url [String] the base URL of the Globus API
  # @param path [String] the path to the Globus API request
  def delete(base_url:, path:)
    response = with_token_refresh_when_unauthorized do
      connection(base_url).delete(path) do |request|
        request.headers['Authorization'] = "Bearer #{config.token}"
      end
    end

    UnexpectedResponse.call(response) unless response.success?

    return nil if response.body.blank?

    JSON.parse(response.body)
  end

  def mkdir(...)
    Endpoint.new(self, ...).tap do |endpoint|
      endpoint.mkdir
      endpoint.allow_writes
    end
  end

  def disallow_writes(...)
    Endpoint
      .new(self, ...)
      .disallow_writes
  end

  def delete_access_rule(...)
    Endpoint
      .new(self, ...)
      .delete_access_rule
  end

  # NOTE: Can't use the `...` (argument forwarding) operator here because we
  #       want to route the keyword args to `Endpoint#new` and the block arg to
  #       `Endpoint#list_files`
  def list_files(**keywords, &)
    Endpoint
      .new(self, **keywords)
      .list_files(&)
  end

  def file_count(...)
    Endpoint
      .new(self, ...)
      .list_files { |files| return files.count }
  end

  def total_size(...)
    Endpoint
      .new(self, ...)
      .list_files { |files| return files.sum(&:size) }
  end

  def get_filenames(...)
    Endpoint
      .new(self, ...)
      .list_files { |files| return files.map(&:name) }
  end

  def has_files?(...)
    Endpoint
      .new(self, ...)
      .has_files?
  end

  def user_valid?(...)
    Identity
      .new(self)
      .valid?(...)
  end

  private

  Config = Struct.new(:client_id, :auth_url, :client_secret, :transfer_endpoint_id, :transfer_url, :uploads_directory, :token, keyword_init: true)

  def connection(base_url)
    Faraday.new(url: base_url) do |conn|
      conn.request :retry, {
        max: 10,
        interval: 0.05,
        interval_randomness: 0.5,
        backoff_factor: 2,
        exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ConnectionFailed]
      }
    end
  end

  # Wraps API operations to request new access token if expired.
  # @yieldreturn response [Faraday::Response] the response to inspect
  #
  # @note You likely want to make sure you're wrapping a _single_ HTTP request in this
  # method, because 1) all calls in the block will be retried from the top if there's
  # an authN failure detected, and 2) only the response returned by the block will be
  # inspected for authN failure.
  # Related: consider that the client instance and its token will live across many
  # invocations of the GlobusClient methods once the client is configured by a consuming application,
  # since this class is a Singleton.  Thus, a token may expire between any two calls (i.e. it
  # isn't necessary for a set of operations to collectively take longer than the token lifetime for
  # expiry to fall in the middle of that related set of HTTP calls).
  def with_token_refresh_when_unauthorized
    response = yield

    # if unauthorized, token has likely expired. try to get a new token and then retry the same request(s).
    if response.status == 401
      config.token = Authenticator.token(config.client_id, config.client_secret, config.auth_url)
      response = yield
    end

    response
  end
end
