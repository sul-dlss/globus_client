# frozen_string_literal: true

class GlobusClient
  # The namespace for endpoint API operations
  class Endpoint # rubocop:disable Metrics/ClassLength
    PATH_SEPARATOR = '/'

    FileInfo = Struct.new(:name, :size)

    # @param client [GlobusClient] a configured instance of the GlobusClient
    # @param path [String] the path to operate on
    # @param user_id [String] a Globus user ID (e.g., a @stanford.edu email address)
    def initialize(client, path:, user_id:)
      @client = client
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
        client.post(
          base_url: client.config.transfer_url,
          path: "#{transfer_path}/mkdir",
          body: { DATA_TYPE: 'mkdir', path: },
          expected_response: lambda { |resp|
                               resp.status == 502 && JSON.parse(resp.body)['code'] == 'ExternalError.MkdirFailed.Exists'
                             }
        )
      end
    end

    # Assign a user read/write permissions for a directory https://docs.globus.org/api/transfer/acl/#rest_access_create
    def allow_writes
      access_request(permissions: 'rw')
    end

    # Assign a user read-only permissions for a directory https://docs.globus.org/api/transfer/acl/#rest_access_create
    def disallow_writes
      update_access_request(permissions: 'r')
    end

    # Delete the access rule https://docs.globus.org/api/transfer/acl/#delete_access_rule
    def delete_access_rule
      raise(StandardError, "Access rule not found for #{path}") unless access_rule_id

      client.delete(
        base_url: client.config.transfer_url,
        path: "#{access_path}/#{access_rule_id}"
      )
    end

    private

    attr_reader :client, :path, :user_id

    def globus_identity_id
      Identity.new(client).get_identity_id(user_id)
    end

    # Builds up a path from a list of path elements. E.g., input would look like:
    #     "mjgiarlo/work123/version1"
    # And this method returns:
    #     ["/uploads/mjgiarlo/", "/uploads/mjgiarlo/work123/", "/uploads/mjgiarlo/work123/version1/"]
    def paths
      @paths ||= path_segments.map.with_index do |_segment, index|
        File
          .join(client.config.uploads_directory, path_segments.slice(..index))
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
      response = client.get(
        base_url: client.config.transfer_url,
        path: "#{transfer_path}/ls",
        params: { path: filepath }
      )

      response['DATA']
        .select { |object| object['type'] == 'file' }
        .each do |file|
        return true if return_presence

        files << FileInfo.new("#{filepath}#{file['name']}", file['size'])
      end

      response['DATA']
        .select { |object| object['type'] == 'dir' }
        .each do |dir|
        # NOTE: This allows the recursive method to short-circuit iff ls_path
        #       returns true, which only happens when return_presence is true
        #       and the first file is found in the ls operation.
        return true if ls_path("#{filepath}#{dir['name']}/", files, return_presence:) == true
      end

      return false if return_presence

      files
    end

    def access_request(permissions:)
      if access_rule_id
        update_access_request(permissions:)
      else
        client.post(
          base_url: client.config.transfer_url,
          path: access_path,
          body: {
            DATA_TYPE: 'access',
            principal_type: 'identity',
            principal: globus_identity_id,
            path: full_path,
            permissions:,
            notify_email: user_id
          }
        )
      end
    end

    def update_access_request(permissions:)
      raise(StandardError, "Access rule not found for #{path}") unless access_rule_id

      client.put(
        base_url: client.config.transfer_url,
        path: "#{access_path}/#{access_rule_id}",
        body: {
          DATA_TYPE: 'access',
          permissions:
        }
      )
    end

    def access_rule
      response = client.get(
        base_url: client.config.transfer_url,
        path: access_list_path,
        content_type: 'application/json'
      )

      response.fetch('DATA').find { |acl| acl['path'] == full_path }
    end

    def access_rule_id
      access_rule&.fetch('id')
    end

    def transfer_path
      "/v0.10/operation/endpoint/#{client.config.transfer_endpoint_id}"
    end

    def access_path
      "/v0.10/endpoint/#{client.config.transfer_endpoint_id}/access"
    end

    def access_list_path
      "/v0.10/endpoint/#{client.config.transfer_endpoint_id}/access_list"
    end
  end
end
