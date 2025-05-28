# frozen_string_literal: true

RSpec.describe GlobusClient::EndpointManager do
  subject(:endpoint_manager) { described_class.new }

  before do
    GlobusClient.configure(
      client_id: 'client_id',
      client_secret: 'client_secret',
      transfer_endpoint_id:,
      transfer_url:,
      uploads_directory: '/uploads/'
    )
  end

  let(:transfer_endpoint_id) { 'NOT_A_REAL_ENDPOINT' }
  let(:transfer_url) { 'https://transfer.api.example.org' }
  let(:owner_id) { 'ac289c59-5f0d-4bff-82c6-ac8c5a68587d' }

  let(:task_list_response) do
    { 'DATA' =>
[{ 'DATA_TYPE' => 'task',
   'bytes_checksummed' => 0,
   'bytes_transferred' => 500,
   'canceled_by_admin' => nil,
   'canceled_by_admin_message' => nil,
   'command' => 'API 0.10 go',
   'completion_time' => '2025-05-14T16:49:23+00:00',
   'deadline' => '2025-05-15T16:49:11+00:00',
   'delete_destination_extra' => false,
   'destination_base_path' => '/uploads/jlittman/new/hierarchical_test/',
   'destination_endpoint' =>
   'u_7ljdyffrsbf63lhxu5puxznaeq#ed23712e-71ad-11ed-a0d5-8d658a17aebf',
   'destination_endpoint_display_name' => 'SDR qa',
   'destination_endpoint_id' => 'e32f7087-d32d-4588-8517-b2d0d32d53b8',
   'destination_host_endpoint' =>
   'u_7ljdyffrsbf63lhxu5puxznaeq#9373ee88-9e19-11eb-9602-491d66228b9d',
   'destination_host_endpoint_display_name' => 'Stanford University Libraries Endpoint',
   'destination_host_endpoint_id' => 'fad23c14-b190-4bed-acf7-a75f4be5a024',
   'destination_host_path' => '/',
   'destination_local_user' => nil,
   'destination_local_user_status' => 'NO_PERMISSION',
   'destination_mapped_collection_display_name' =>
   'Stanford University Libraries Globus Endpoint',
   'destination_mapped_collection_id' => 'efb4a78e-4d00-49da-8736-01b53e347f0b',
   'directories' => 0,
   'effective_bytes_per_second' => 41,
   'encrypt_data' => true,
   'fail_on_quota_errors' => false,
   'fatal_error' => nil,
   'faults' => 0,
   'files' => 2,
   'files_skipped' => 0,
   'files_transferred' => 2,
   'filter_rules' => nil,
   'history_deleted' => false,
   'is_ok' => nil,
   'is_paused' => false,
   'label' => nil,
   'nice_status' => nil,
   'nice_status_details' => nil,
   'nice_status_expires_in' => nil,
   'nice_status_short_description' => nil,
   'owner_id' => 'ac289c59-5f0d-4bff-82c6-ac8c5a68587d',
   'owner_string' => 'jlittman@stanford.edu',
   'preserve_timestamp' => false,
   'recursive_symlinks' => 'ignore',
   'request_time' => '2025-05-14T16:49:11+00:00',
   'skip_source_errors' => false,
   'source_base_path' => nil,
   'source_endpoint' => 'u_m2j2244hsbfdfajav36ja22gy4#cb70ab9a-1002-11ec-bf11-edb00af5aa74',
   'source_endpoint_display_name' => 'Stanford Google Drive',
   'source_endpoint_id' => 'e1c8858b-d5aa-4e36-b97e-95913047ec2b',
   'source_host_endpoint' => nil,
   'source_host_endpoint_display_name' => nil,
   'source_host_endpoint_id' => nil,
   'source_host_path' => nil,
   'source_local_user' => nil,
   'source_local_user_status' => 'NO_PERMISSION',
   'source_mapped_collection_display_name' => nil,
   'source_mapped_collection_id' => nil,
   'status' => 'SUCCEEDED',
   'subtasks_canceled' => 0,
   'subtasks_expired' => 0,
   'subtasks_failed' => 0,
   'subtasks_pending' => 0,
   'subtasks_retrying' => 0,
   'subtasks_skipped_errors' => 0,
   'subtasks_succeeded' => 4,
   'subtasks_total' => 4,
   'symlinks' => 0,
   'sync_level' => nil,
   'task_id' => '5b33e781-30e3-11f0-960c-02e36a640ad1',
   'type' => 'TRANSFER',
   'username' => 'u_vqujywk7bvf77awgvsgfu2cypu',
   'verify_checksum' => true },
 { 'DATA_TYPE' => 'task',
   'bytes_checksummed' => 0,
   'bytes_transferred' => 250,
   'canceled_by_admin' => nil,
   'canceled_by_admin_message' => nil,
   'command' => 'API 0.10 go',
   'completion_time' => '2025-05-14T16:08:52+00:00',
   'deadline' => '2025-05-15T16:08:43+00:00',
   'delete_destination_extra' => false,
   'destination_base_path' => '/uploads/jlittman/new/',
   'destination_endpoint' =>
   'u_7ljdyffrsbf63lhxu5puxznaeq#ed23712e-71ad-11ed-a0d5-8d658a17aebf',
   'destination_endpoint_display_name' => 'SDR qa',
   'destination_endpoint_id' => 'e32f7087-d32d-4588-8517-b2d0d32d53b8',
   'destination_host_endpoint' =>
   'u_7ljdyffrsbf63lhxu5puxznaeq#9373ee88-9e19-11eb-9602-491d66228b9d',
   'destination_host_endpoint_display_name' => 'Stanford University Libraries Endpoint',
   'destination_host_endpoint_id' => 'fad23c14-b190-4bed-acf7-a75f4be5a024',
   'destination_host_path' => '/',
   'destination_local_user' => nil,
   'destination_local_user_status' => 'NO_PERMISSION',
   'destination_mapped_collection_display_name' =>
   'Stanford University Libraries Globus Endpoint',
   'destination_mapped_collection_id' => 'efb4a78e-4d00-49da-8736-01b53e347f0b',
   'directories' => 0,
   'effective_bytes_per_second' => 27,
   'encrypt_data' => true,
   'fail_on_quota_errors' => false,
   'fatal_error' => nil,
   'faults' => 0,
   'files' => 1,
   'files_skipped' => 0,
   'files_transferred' => 1,
   'filter_rules' => nil,
   'history_deleted' => false,
   'is_ok' => nil,
   'is_paused' => false,
   'label' => nil,
   'nice_status' => nil,
   'nice_status_details' => nil,
   'nice_status_expires_in' => nil,
   'nice_status_short_description' => nil,
   'owner_id' => 'ac289c59-5f0d-4bff-82c6-ac8c5a68587d',
   'owner_string' => 'jlittman@stanford.edu',
   'preserve_timestamp' => false,
   'recursive_symlinks' => 'ignore',
   'request_time' => '2025-05-14T16:08:43+00:00',
   'skip_source_errors' => false,
   'source_base_path' => nil,
   'source_endpoint' => 'u_m2j2244hsbfdfajav36ja22gy4#cb70ab9a-1002-11ec-bf11-edb00af5aa74',
   'source_endpoint_display_name' => 'Stanford Google Drive',
   'source_endpoint_id' => 'e1c8858b-d5aa-4e36-b97e-95913047ec2b',
   'source_host_endpoint' => nil,
   'source_host_endpoint_display_name' => nil,
   'source_host_endpoint_id' => nil,
   'source_host_path' => nil,
   'source_local_user' => nil,
   'source_local_user_status' => 'NO_PERMISSION',
   'source_mapped_collection_display_name' => nil,
   'source_mapped_collection_id' => nil,
   'status' => 'SUCCEEDED',
   'subtasks_canceled' => 0,
   'subtasks_expired' => 0,
   'subtasks_failed' => 0,
   'subtasks_pending' => 0,
   'subtasks_retrying' => 0,
   'subtasks_skipped_errors' => 0,
   'subtasks_succeeded' => 2,
   'subtasks_total' => 2,
   'symlinks' => 0,
   'sync_level' => nil,
   'task_id' => 'b4802ba0-30dd-11f0-ad57-0afffb017b7d',
   'type' => 'TRANSFER',
   'username' => 'u_vqujywk7bvf77awgvsgfu2cypu',
   'verify_checksum' => true }],
      'DATA_TYPE' => 'task_list',
      'has_next_page' => false,
      'last_key' => 'complete,2025-05-09T14:52:38.760943' }
  end

  describe '#task_list' do
    context 'when no parameters are provided' do
      before do
        stub_request(:get, "#{transfer_url}/v0.10/endpoint_manager/task_list")
          .with(query: { filter_endpoint: transfer_endpoint_id })
          .to_return(status: 200, body: task_list_response.to_json)
      end

      it 'returns all task documents' do
        expect(endpoint_manager.task_list).to eq(task_list_response['DATA'])
      end
    end

    context 'when parameters are provided' do
      before do
        stub_request(:get, "#{transfer_url}/v0.10/endpoint_manager/task_list")
          .with(query: {
                  filter_endpoint: transfer_endpoint_id,
                  filter_owner_id: owner_id,
                  filter_status: 'ACTIVE,INACTIVE'
                })
          .to_return(status: 200, body: task_list_response.to_json)
      end

      it 'returns filtered task documents' do
        expect(endpoint_manager.task_list(owner_id:, status: described_class::IN_PROGRESS_STATUSES,
                                          destination_path: '/uploads/jlittman/new/hierarchical_test'))
          .to eq([task_list_response['DATA'].first])
      end
    end
  end

  describe '#tasks_in_progress?' do
    before do
      stub_request(:get, "#{transfer_url}/v0.10/endpoint_manager/task_list")
        .with(query: {
                filter_endpoint: transfer_endpoint_id,
                filter_owner_id: owner_id,
                filter_status: 'ACTIVE,INACTIVE'
              })
        .to_return(status: 200, body: task_list_response.to_json)
    end

    context 'when there are tasks' do
      it 'returns true' do
        expect(endpoint_manager.tasks_in_progress?(owner_id:, destination_path: '/uploads/jlittman/new/')).to be true
      end
    end

    context 'when there are no tasks' do
      it 'returns false' do
        expect(endpoint_manager.tasks_in_progress?(owner_id:, destination_path: '/uploads/notjlittman/new/')).to be false
      end
    end
  end
end
