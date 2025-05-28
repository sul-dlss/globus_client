# frozen_string_literal: true

class GlobusClient
  # The namespace for endpoint management API operations
  class EndpointManager
    IN_PROGRESS_STATUSES = %w[ACTIVE INACTIVE].freeze

    # List tasks for the configured transfer endpoint
    # https://docs.globus.org/api/transfer/advanced_collection_management/#get_tasks
    # Note that this method does not support pagination, as there are unlikely to be many tasks.
    # Also note that if destination_path is provided, only transfer tasks will be returned.
    # @param owner_id [String] the Globus user ID (a UUID, not email address)
    # @param status [Array] the status of the tasks to filter on. Values are ACTIVE, INACTIVE, SUCCEEDED, or FAILED.
    # @param destination_path [String] the destination path to filter tasks by
    # @return [Array] list of task documents
    def task_list(owner_id: nil, status: [], destination_path: nil)
      tasks = GlobusClient.instance.get(
        base_url: GlobusClient.config.transfer_url,
        path: '/v0.10/endpoint_manager/task_list',
        params: task_list_params(owner_id:, status:)
      )['DATA']
      return tasks unless destination_path

      destination_base_path = destination_path.delete_suffix('/') << '/'
      tasks.select { |task| task['destination_base_path']&.start_with?(destination_base_path) }
    end

    # @param owner_id [String] the Globus user ID (a UUID, not email address)
    # @param destination_path [String] the destination path to filter tasks by
    # @return [boolean] true if there are tasks in progress
    def tasks_in_progress?(owner_id: nil, destination_path: nil)
      task_list(owner_id:, destination_path:, status: IN_PROGRESS_STATUSES).present?
    end

    private

    def task_list_params(owner_id:, status:)
      {
        filter_endpoint: GlobusClient.config.transfer_endpoint_id,
        filter_owner_id: owner_id,
        filter_status: Array(status).join(',').presence
      }.compact
    end
  end
end
