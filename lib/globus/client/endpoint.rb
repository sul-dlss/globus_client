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

      # This is a temporary method to show parsing of data returned.
      def length
        objects['total']
      end

      # Create a directory https://docs.globus.org/api/transfer/file_operations/#make_directory
      def mk_dir(sunet:, work_id:, version:)
        sunet = sunet.delete_suffix('@stanford.edu')
        path = Settings.globus.uploads_dir
        dirs = [sunet, work_id, "version#{version}"]

        # transfer API does not support recursive directory creation
        dirs.each do |dir|
          path = "#{path}#{dir}/"
          response = call_mkdir(path)
          if response.status == 502
            error = JSON.parse(response.body)
            next if error['code'] == 'ExternalError.MkdirFailedExists'

            UnexpectedResponse.call(response)
          else
            UnexpectedResponse.call(response) unless response.success?
          end
        end
      end

      private

      # @return [Faraday::Response]
      def call_mkdir(path)
        endpoint = "/v0.10/operation/endpoint/#{Settings.globus.endpoint}/mkdir"
        connection.post(endpoint) do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = {
            DATA_TYPE: 'mkdir',
            path:
          }.to_json
        end
      end

      def objects
        # List files at an endpoint https://docs.globus.org/api/transfer/file_operations/#list_directory_contents
        endpoint = "/v0.10/operation/endpoint/#{Settings.globus.endpoint}/ls"
        response = connection.get(endpoint)
        UnexpectedResponse.call(response) unless response.success?
        JSON.parse(response.body)
      end
    end
  end
end
