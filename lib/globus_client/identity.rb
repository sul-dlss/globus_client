# frozen_string_literal: true

class GlobusClient
  # Lookup of a Globus identity ID
  class Identity
    def initialize(client)
      @client = client
    end

    # @param user_id [String] the username in the form of an email addresss
    # @return [Hash] id and status of Globus identity
    def get_identity(user_id)
      response = client.get(
        base_url: client.config.auth_url,
        path: "/v2/api/identities",
        params: {usernames: user_id}
      )

      response["identities"].find { |id| id["username"] == user_id }
    end

    # @param user_id [String] the username in the form of an email addresss
    # @return [Boolean] whether the account has a valid status
    def valid?(user_id)
      %w[used private unused].include?(get_identity(user_id)["status"])
    end

    # @param user_id [String] the username in the form of an email addresss
    # @return [String] UUID for Globus identity
    def get_identity_id(user_id)
      get_identity(user_id)["id"]
    end

    private

    attr_reader :client
  end
end
