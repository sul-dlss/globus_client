# frozen_string_literal: true

require_relative "client/version"
require "active_support/core_ext/module/delegation"
require "globus/client/authenticator"
require "globus/client/endpoint"

module Globus
  class Error < StandardError; end
  # Your code goes here...

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
