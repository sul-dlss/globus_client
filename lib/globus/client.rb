# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'faraday'
require 'globus/client/version'
require 'globus/client/authenticator'
require 'globus/client/endpoint'
require 'globus/client/identity'
require 'globus/client/unexpected_response'

module Globus
  # Client for creating connections
  class Client
    def initialize(client_id, client_secret)
      @client_id = client_id
      @client_secret = client_secret
      @authenticator = Globus::Client::Authenticator.new(client_id, client_secret)
    end

    attr_accessor :authenticator, :client_id, :client_secret

    def token
      @token ||= authenticator.token
    end
  end
end
