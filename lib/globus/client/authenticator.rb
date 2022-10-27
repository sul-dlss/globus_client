# frozen_string_literal: true

require "faraday"

module Globus
  class Client
    # The namespace for the "login" command
    class Authenticator
      def initialize(client_id, client_secret)
        @client_id = client_id
        @client_secret = client_secret
      end

      attr_accessor :client_id, :client_secret

      def token
        # Request an access_token
        form_data = { client_id: client_id,
                      client_secret: client_secret,
                      encoding: "form",
                      grant_type: "client_credentials",
                      scope: "urn:globus:auth:scope:transfer.api.globus.org:all" }

        auth_url = Settings.globus.token_url
        conn = Faraday.new(
          url: auth_url
        )

        response = conn.post("/v2/oauth2/token", form_data)
        puts response.body
        JSON.parse(response.body)["access_token"]
      end
    end
  end
end
