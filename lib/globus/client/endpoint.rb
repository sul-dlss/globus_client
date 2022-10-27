# frozen_string_literal: true

require 'faraday'

module Globus
  class Client
    # The namespace for the "login" command
    class Endpoint
      ENDPOINT_ID = '34ea3e65-6831-479a-8da3-87f118e3fc2b'

      def initialize(token)
        @token = token
      end

      attr_reader :token

      def connection
        # Transfer API connection
        Faraday.new(
          url: 'https://transfer.api.globusonline.org',
          headers: { 'Authorization': "Bearer #{token}" }
        )
      end

      def list_stuff
        # List files at an endpoint https://docs.globus.org/api/transfer/file_operations/#list_directory_contents
        ls_endpoint = "/v0.10/operation/endpoint/#{ENDPOINT_ID}/ls"
        ls_resp = connection.get(ls_endpoint)
        ls_resp.body
      end
    end
  end
end
