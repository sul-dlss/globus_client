# frozen_string_literal: true

class GlobusClient
  # The namespace for the "login" command
  class Authenticator
    def self.token
      new.token
    end

    # Request an access_token
    def token
      response = connection.post('/v2/oauth2/token', form_data)

      UnexpectedResponse.call(response) unless response.success?

      JSON.parse(response.body)['access_token']
    end

    private

    def connection
      Faraday.new(url: GlobusClient.config.auth_url)
    end

    def form_data
      {
        client_id: GlobusClient.config.client_id,
        client_secret: GlobusClient.config.client_secret,
        encoding: 'form',
        grant_type: 'client_credentials',
        scope: 'urn:globus:auth:scope:transfer.api.globus.org:all'
      }
    end
  end
end
