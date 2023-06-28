# frozen_string_literal: true

class GlobusClient
  # Lookup of a Globus identity ID
  class Identity
    def initialize(config)
      @config = config
    end

    # @param user_id [String] the username in the form of an email addresss
    # @return [Hash] id and status of Globus identity
    def get_identity(user_id)
      @email = user_id
      response = lookup_identity
      UnexpectedResponse.call(response) unless response.success?

      data = JSON.parse(response.body)
      extract_id(data)
    end

    # @param user_id [String] the username in the form of an email addresss
    # @return [Boolean] whether the account has a valid status
    def valid?(user_id)
      ["used", "private", "unused"].include?(get_identity(user_id)["status"])
    end

    # @param user_id [String] the username in the form of an email addresss
    # @return [String] UUID for Globus identity
    def get_identity_id(user_id)
      get_identity(user_id)["id"]
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
      identities.find { |id| id["username"] == @email }
    end
  end
end
