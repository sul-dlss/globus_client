# frozen_string_literal: true

require 'faraday'

module Globus
  class Client
    # The namespace for the "login" command
    class Endpoint
      def initialize(token)
        @token = token
      end

      attr_reader :token

      def connection
        # Transfer API connection
        Faraday.new(
          url: Settings.globus.transfer_url,
          headers: { 'Authorization': "Bearer #{token}" }
        )
      end

      def length
        objects['total']
      end

      private

      def objects
        # List files at an endpoint https://docs.globus.org/api/transfer/file_operations/#list_directory_contents
        ls_endpoint = "/v0.10/operation/endpoint/#{Settings.globus.endpoint}/ls"
        ls_resp = connection.get(ls_endpoint)
        JSON.parse(ls_resp.body)
      end
    end
  end
end
