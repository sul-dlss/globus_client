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

      def file_count
        objects["total"]
      end

      def total_size
        files.sum { |file| file["size"] }
      end

      # Create a directory https://docs.globus.org/api/transfer/file_operations/#make_directory
      def mkdir
        # transfer API does not support recursive directory creation
        paths.each do |path|
          response = connection.post("#{transfer_path}/mkdir") do |req|
            req.headers["Content-Type"] = "application/json"
            req.body = {
              DATA_TYPE: "mkdir",
              path:
            }.to_json
          end

          next if response.success?

          # Ignore error if directory already exists
          if response.status == 502
            error = JSON.parse(response.body)
            next if error["code"] == "ExternalError.MkdirFailed.Exists"
          end

          UnexpectedResponse.call(response)
        end
      end

      # Assign a user read/write permissions for a directory https://docs.globus.org/api/transfer/acl/#rest_access_create
      def allow_writes
        response = connection.post(access_path) do |req|
          req.body = {
            DATA_TYPE: "access",
            principal_type: "identity",
            principal: identity.get_identity_id(user_id),
            path: paths.last,
            permissions: "rw",
            notify_email: "#{user_id}@stanford.edu"
          }.to_json
          req.headers["Content-Type"] = "application/json"
        end

        return response if response.success?

        # Ignore error if permissions already set for identity
        if response.status == 409
          error = JSON.parse(response.body)
          return if error["code"] == "Exists"
        end

        UnexpectedResponse.call(response)
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

      def identity
        Globus::Client::Identity.new(config)
      end

      # Builds up a path from a list of path elements. E.g., input would look like:
      #     ["mjgiarlo", "work123", "version1"]
      # And this method returns:
      #     ["/uploads/mjgiarlo/", "/uploads/mjgiarlo/work123/", "/uploads/mjgiarlo/work123/version1/"]
      def paths
        path_segments.map.with_index do |_segment, index|
          File.join(config.uploads_directory, path_segments.slice(..index)).concat("/")
        end
      end

      def path_segments
        [user_id, "work#{work_id}", "version#{work_version}"]
      end

      def objects
        # List files at an endpoint https://docs.globus.org/api/transfer/file_operations/#list_directory_contents
        response = connection.get("#{transfer_path}/ls?path=#{paths.last}")
        return JSON.parse(response.body) if response.success?

        UnexpectedResponse.call(response)
      end

      def transfer_path
        "/v0.10/operation/endpoint/#{config.transfer_endpoint_id}"
      end

      def access_path
        "/v0.10/endpoint/#{config.transfer_endpoint_id}/access"
      end

      def files
        objects["DATA"].select { |object| object["DATA_TYPE"] == "file" }
      end
    end
  end
end
