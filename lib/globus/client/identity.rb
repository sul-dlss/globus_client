# frozen_string_literal: true

require 'faraday'

module Globus
  class Client
    # Lookup of a Globus identity ID
    class Identity
      def initialize(token)
        @token = token
      end

      attr_reader :token

      def connection
        Faraday.new(
          url: Settings.globus.auth_url
        )
      end

      def lookup_identity
        id_endpoint = '/v2/api/identities'
        connection.get(id_endpoint) do |req|
          req.params['usernames'] = @email
          req.headers['Authorization'] = "Bearer #{token}"
        end
      end

      def get_identity_id(email)
        @email = email
        raise StandardError, "Identity #{email} should be in form of: sunet@stanford.edu." unless valid?(@email)

        response = lookup_identity
        UnexpectedResponse.call(response) unless response.success?

        data = JSON.parse(response.body)
        extract_id(data)
      end

      private

      def valid?(email)
        return true if email.end_with? '@stanford.edu'

        false
      end

      def extract_id(data)
        identities = data['identities']
        # Select identity with "used" or "private" status
        matching_users = identities.select { |id| id['username'] == @email }
        active_users = matching_users.select { |user| (user['status'] == 'used' || user['status'] == 'private') }
        raise StandardError "No matching active Globus user found for #{@email}." if active_users.empty?

        active_users.first['id']
      end
    end
  end
end
