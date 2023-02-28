# frozen_string_literal: true

class GlobusClient
  # The namespace for endpoint API operations
  class Endpoint
    PATH_SEPARATOR = "/"

    FileInfo = Struct.new(:name, :size)

    # @param config [#token, #uploads_directory, #transfer_endpoint_id, #transfer_url, #auth_url] configuration for the gem
    # @param path [String] the path to operate on
    # @param user_id [String] a Globus user ID (e.g., a @stanford.edu email address)
    def initialize(config, path:, user_id:)
      @config = config
      @user_id = user_id
      @path = path
    end

    def has_files?
      ls_path(full_path, [], return_presence: true)
    end

    def list_files
      ls_path(full_path, []).tap do |files|
        yield files if block_given?
      end
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
      access_request(permissions: "rw")
    end

    # Assign a user read-only permissions for a directory https://docs.globus.org/api/transfer/acl/#rest_access_create
    def disallow_writes
      access_request(permissions: "r")
    end

    private

    attr_reader :config, :path, :user_id

    def connection
      # Creates a new connection every time to avoid firewall timeouts when
      # doing many requests over one connection.
      # https://github.com/sul-dlss/happy-heron/issues/3008
      Faraday.new(
        url: config.transfer_url,
        headers: {Authorization: "Bearer #{config.token}"}
      )
    end

    def globus_identity_id
      Identity.new(config).get_identity_id(user_id)
    end

    # Builds up a path from a list of path elements. E.g., input would look like:
    #     "mjgiarlo/work123/version1"
    # And this method returns:
    #     ["/uploads/mjgiarlo/", "/uploads/mjgiarlo/work123/", "/uploads/mjgiarlo/work123/version1/"]
    def paths
      @paths ||= path_segments.map.with_index do |_segment, index|
        File
          .join(config.uploads_directory, path_segments.slice(..index))
          .concat(PATH_SEPARATOR)
      end
    end

    # @see #paths
    def full_path
      paths.last
    end

    def path_segments
      raise ArgumentError, "Unexpected path provided: #{path.inspect}" unless path.respond_to?(:split)

      path.split(PATH_SEPARATOR)
    end

    # List files recursively at an endpoint https://docs.globus.org/api/transfer/file_operations/#list_directory_contents
    # @param filepath [String] an absolute path to look up contents e.g. /uploads/example/work123/version1
    # @param files [Array<FileInfo>] an array of FileInfo structs, each of which has a name and a size
    # @param return_presence [Boolean] if true, return a boolean to indicate if any files at all are present, short-circuiting the recursive operation
    def ls_path(filepath, files, return_presence: false)
      response = connection.get("#{transfer_path}/ls?path=#{filepath}")
      return UnexpectedResponse.call(response) unless response.success?

      data = JSON.parse(response.body)["DATA"]
      data
        .select { |object| object["type"] == "file" }
        .each do |file|
        return true if return_presence

        files << FileInfo.new("#{filepath}#{file["name"]}", file["size"])
      end
      data
        .select { |object| object["type"] == "dir" }
        .each do |dir|
        # NOTE: This allows the recursive method to short-circuit iff ls_path
        #       returns true, which only happens when return_presence is true
        #       and the first file is found in the ls operation.
        return true if ls_path("#{filepath}#{dir["name"]}/", files, return_presence:) == true
      end

      return false if return_presence

      files
    end

    def access_request(permissions:)
      response = if access_rule_id
        connection.put("#{access_path}/#{access_rule_id}") do |req|
          req.body = {
            DATA_TYPE: "access",
            permissions:
          }.to_json
          req.headers["Content-Type"] = "application/json"
        end
      else
        connection.post(access_path) do |req|
          req.body = {
            DATA_TYPE: "access",
            principal_type: "identity",
            principal: globus_identity_id,
            path: full_path,
            permissions:,
            notify_email: user_id
          }.to_json
          req.headers["Content-Type"] = "application/json"
        end
      end

      return true if response.success?

      UnexpectedResponse.call(response)
    end

    def access_rule
      response = connection.get(access_list_path) do |req|
        req.headers["Content-Type"] = "application/json"
      end

      JSON
        .parse(response.body)["DATA"]
        .find { |acl| acl["path"] == full_path }
    end

    def access_rule_id
      access_rule&.fetch("id")
    end

    def transfer_path
      "/v0.10/operation/endpoint/#{config.transfer_endpoint_id}"
    end

    def access_path
      "/v0.10/endpoint/#{config.transfer_endpoint_id}/access"
    end

    def access_list_path
      "/v0.10/endpoint/#{config.transfer_endpoint_id}/access_list"
    end
  end
end
