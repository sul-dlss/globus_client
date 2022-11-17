# frozen_string_literal: true

require 'faraday'

module Globus
  class Client
    # The namespace for endpoint API operations
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

      def endpoint
        "/v0.10/operation/endpoint/#{Settings.globus.endpoint}"
      end

      # This is a temporary method to show parsing of data returned.
      def length
        objects['total']
      end

      # Create a directory https://docs.globus.org/api/transfer/file_operations/#make_directory
      # @param sunetid [String] sunetid (not email address)
      # @param work_id [String] the h2 work id
      # @param version [String] the h2 work's version number
      def mk_dir(sunetid:, work_id:, version:)
        path = Settings.globus.uploads_dir
        dirs = [sunetid, "work#{work_id}", "version#{version}"]

        # transfer API does not support recursive directory creation
        dirs.each do |dir|
          path = "#{path}#{dir}/"
          response = call_mkdir(path)
          # if directory already exists
          if response.status == 502
            error = JSON.parse(response.body)
            next if error['code'] == 'ExternalError.MkdirFailedExists'

            UnexpectedResponse.call(response)
          else
            UnexpectedResponse.call(response) unless response.success?
          end
        end
      end

      # Assign a user read/write permissions for a directory https://docs.globus.org/api/transfer/acl/#rest_access_create
      # @param sunetid [String] sunetid (not email address)
      # @param work_id [String] the h2 work id
      # @param version [String] the h2 work's version number
      def set_permissions(sunetid:, work_id:, version:)
        path = "#{Settings.globus.uploads_dir}/#{sunetid}/work#{work_id}/version#{version}/"
        identity = Globus::Client::Identity.new(token)
        id = identity.get_identity_id(sunetid)
        call_access(path:, id:, sunetid:)
      end

      private

      # @return [Faraday::Response]
      def call_mkdir(path)
        response = connection.post("#{endpoint}/mkdir") do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = {
            DATA_TYPE: 'mkdir',
            path:
          }.to_json
        end
        UnexpectedResponse.call(response) unless response.success?

        response
      end

      # @param path [String] the directory on the globus endpoint
      # @param id [String] globus identifier associated with the sunetid email
      # @param sunetid [String] sunetid, not email address
      # @return [Faraday::Response]
      def call_access(path:, id:, sunetid:)
        response = connection.post("#{endpoint}/access") do |req|
          req.body = {
            DATA_TYPE: 'access',
            principal_type: 'identity',
            principal: id,
            path:,
            permissions: 'rw',
            notify_email: "#{sunetid}@stanford.edu"
          }.to_json
          req.headers['Content-Type'] = 'application/json'
        end
        UnexpectedResponse.call(response) unless response.success?

        response
      end

      def objects
        # List files at an endpoint https://docs.globus.org/api/transfer/file_operations/#list_directory_contents
        response = connection.get("#{endpoint}/ls")
        UnexpectedResponse.call(response) unless response.success?
        JSON.parse(response.body)
      end
    end
  end
end
