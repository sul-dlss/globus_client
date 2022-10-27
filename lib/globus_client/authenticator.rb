# frozen_string_literal: true

require 'faraday'

module GlobusClient
  # The namespace for the "login" command
  class Authenticator
    LOGIN_PATH = 'https://auth.globus.org/v2/oauth2/token'
    ENDPOINT_ID = '34ea3e65-6831-479a-8da3-87f118e3fc2b'

    def initialize(client_id, client_secret)
      @client_id = client_id
      @client_secret = client_secret
    end

    attr_accessor :client_id, :client_secret

    def token
      # Request an access_token
      form_data = { 'client_id': client_id,
                    'client_secret': client_secret,
                    'encoding': 'form',
                    'grant_type': 'client_credentials',
                    'scope': 'urn:globus:auth:scope:transfer.api.globus.org:all' }

      auth_url = 'https://auth.globus.org/'
      conn = Faraday.new(
        url: auth_url
      )

      response = conn.post('/v2/oauth2/token', form_data)
      token = JSON.parse(response.body)['access_token']
    end
  end
end
