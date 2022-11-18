# frozen_string_literal: true

module Globus
  class Client
    # Lookup of a Globus identity ID
    class Identity
      def initialize(config)
        @config = config
      end

      def get_identity_id(sunetid)
        @email = "#{sunetid}@stanford.edu"

        response = lookup_identity
        UnexpectedResponse.call(response) unless response.success?

        data = JSON.parse(response.body)
        extract_id(data)
      end

      private

      attr_reader :config

      def connection
        Faraday.new(url: config.auth_url)
      end

      def lookup_identity
        id_endpoint = "/v2/api/identities"
        connection.get(id_endpoint) do |req|
          req.params["usernames"] = @email
          req.headers["Authorization"] = "Bearer #{config.token}"
        end
      end

      def extract_id(data)
        identities = data["identities"]
        # Select identity with "used" or "private" status
        matching_users = identities.select { |id| id["username"] == @email }
        active_users = matching_users.select { |user| (user["status"] == "used" || user["status"] == "private") }
        raise StandardError "No matching active Globus user found for #{@email}." if active_users.empty?

        active_users.first["id"]
      end
    end
  end
end
