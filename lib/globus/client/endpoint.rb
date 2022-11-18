# frozen_string_literal: true

module Globus
  class Client
    # The namespace for endpoint API operations
    class Endpoint
      # @param config [#token, #uploads_directory, #transfer_endpoint_id, #transfer_url, #auth_url] configuration for the gem
      # @param user_id [String] conventionally, we use the SUNet ID, not an email address
      # @param work_id [#to_s] the identifier of the work (e.g., an H2 work)
      # @param work_version [#to_s] the version of the work (e.g., an H2 version)
      def initialize(config, user_id:, work_id:, work_version:)
        @config = config
        @user_id = user_id
        @work_id = work_id
        @work_version = work_version
      end

      # This is a temporary method to show parsing of data returned.
      def length
        objects["total"]
      end

      # Create a directory https://docs.globus.org/api/transfer/file_operations/#make_directory
      def mkdir
        path = config.uploads_directory
        dirs = [user_id, "work#{work_id}", "version#{work_version}"]

        # transfer API does not support recursive directory creation
        dirs.each do |dir|
          path = "#{path}#{dir}/"
          response = call_mkdir(path)
          # if directory already exists
          if response.status == 502
            error = JSON.parse(response.body)
            next if error["code"] == "ExternalError.MkdirFailedExists"

            UnexpectedResponse.call(response)
          else
            UnexpectedResponse.call(response) unless response.success?
          end
        end
      end

      # Assign a user read/write permissions for a directory https://docs.globus.org/api/transfer/acl/#rest_access_create
      def set_permissions
        path = "#{config.uploads_directory}/#{user_id}/work#{work_id}/version#{work_version}/"
        identity = Globus::Client::Identity.new(config)
        id = identity.get_identity_id(user_id)
        call_access(path:, id:, user_id:)
      end

      private

      attr_reader :config, :user_id, :work_id, :work_version

      def connection
        # Transfer API connection
        Faraday.new(
          url: config.transfer_url,
          headers: {Authorization: "Bearer #{config.token}"}
        )
      end

      def endpoint
        "/v0.10/operation/endpoint/#{config.transfer_endpoint_id}"
      end

      # @return [Faraday::Response]
      def call_mkdir(path)
        response = connection.post("#{endpoint}/mkdir") do |req|
          req.headers["Content-Type"] = "application/json"
          req.body = {
            DATA_TYPE: "mkdir",
            path:
          }.to_json
        end
        UnexpectedResponse.call(response) unless response.success?

        response
      end

      # Makes the API call to Globus to set permissions
      # @param path [String] the directory on the globus endpoint
      # @param id [String] globus identifier associated with the user_id email
      # @param user_id [String] user_id, not email address
      # @return [Faraday::Response]
      def call_access(path:, id:, user_id:)
        response = connection.post("#{endpoint}/access") do |req|
          req.body = {
            DATA_TYPE: "access",
            principal_type: "identity",
            principal: id,
            path:,
            permissions: "rw",
            notify_email: "#{user_id}@stanford.edu"
          }.to_json
          req.headers["Content-Type"] = "application/json"
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
