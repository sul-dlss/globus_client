# frozen_string_literal: true

class GlobusClient
  # The namespace for the "login" command
  class Authenticator
    def self.token(client_id, client_secret, auth_url)
      new(client_id, client_secret, auth_url).token
    end

    def initialize(client_id, client_secret, auth_url)
      @client_id = client_id
      @client_secret = client_secret
      @auth_url = auth_url
    end

    # Request an access_token
    def token
      response = connection.post('/v2/oauth2/token', form_data)

      UnexpectedResponse.call(response) unless response.success?

      JSON.parse(response.body)['access_token']
    end

    private

    attr_reader :client_id, :client_secret, :auth_url

    def connection
      Faraday.new(url: auth_url)
    end

    def form_data
      {
        client_id:,
        client_secret:,
        encoding: 'form',
        grant_type: 'client_credentials',
        scope: 'urn:globus:auth:scope:transfer.api.globus.org:all'
      }
    end
  end
end
