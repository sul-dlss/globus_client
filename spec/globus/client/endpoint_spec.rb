# frozen_string_literal: true

RSpec.describe Globus::Client::Endpoint do
  context 'with a valid token' do
    let(:client_id) { Settings.globus.client_id }
    let(:client_secret) { Settings.globus.client_secret }
    let(:globus_client) { Globus::Client.new(client_id, client_secret) }
    let(:globus_endpoint) { Settings.globus.endpoint }
    let(:endpoint) { described_class.new(globus_client.token) }
    let(:token_response) do
      {
        access_token: 'a_long_silly_token',
        scope: 'urn:globus:auth:scope:transfer.api.globus.org:all',
        expires_in: 172_800,
        token_type: 'Bearer',
        resource_server: 'transfer.api.globus.org',
        other_tokens: []
      }
    end
    let(:list_response) do
      {
        DATA: [
          {
            DATA_TYPE: 'file',
            group: 'globus',
            last_modified: '2022-10-20 20:09:40+00:00',
            link_group: nil,
            link_last_modified: nil,
            link_size: nil,
            link_target: nil,
            link_user: nil,
            name: 'read-test',
            permissions: '0755',
            size: 3,
            type: 'dir',
            user: 'globus'
          }
        ],
        DATA_TYPE: 'file_list',
        absolute_path: '/',
        endpoint: "#{Settings.globus.endpoint}",
        length: 1,
        path: '/~/',
        rename_supported: true,
        symlink_supported: false,
        total: 1
      }
    end
    let(:mkdir_response) do
      {
        'DATA_TYPE': 'mkdir_result',
        'code': 'DirectoryCreated',
        'message': 'The directory was created successfully',
        'request_id': '12345',
        'resource': '/operation/endpoint/an-endpoint-identifier/mkdir'
      }
    end

    context 'when listing files' do
      before do
        stub_request(:post, "#{Settings.globus.auth_url}/v2/oauth2/token")
          .to_return(status: 200, body: token_response.to_json)

        stub_request(:get, "#{Settings.globus.transfer_url}/v0.10/operation/endpoint/#{globus_endpoint}/ls")
          .to_return(status: 200, body: list_response.to_json)
      end

      it '#list_stuff' do
        expect(endpoint.length).to eq 1
      end
    end

    context 'when creating a directory that does not exist' do
      let(:user) { 'example@stanford.edu' }
      let(:work) { 'work123' }
      let(:version) { '1' }

      before do
        stub_request(:post, "#{Settings.globus.auth_url}/v2/oauth2/token")
          .to_return(status: 200, body: token_response.to_json)

        stub_request(:post, "#{Settings.globus.transfer_url}/v0.10/operation/endpoint/#{globus_endpoint}/mkdir")
          .to_return(status: 202, body: mkdir_response.to_json)
      end

      it '#mk_dir' do
        expect { endpoint.mk_dir(sunet: user, work_id: work, version:) }.not_to raise_error
      end
    end

    context 'when creating a directory for a user that exists' do
      let(:user) { 'example@stanford.edu' }
      let(:work) { 'work123' }
      let(:version) { '1' }
      let(:mkdir_response_user) do
        {
          code: 'ExternalError.MkdirFailed.Exists',
          message: "Path already exists, Error Path '/uploads/example/' already exists\n",
          request_id: '1234',
          resource: '/operation/endpoint/an-endpoint-id/mkdir'
        }
      end
      let(:user_request_body) do
        {
          DATA_TYPE: 'mkdir',
          path: '/uploads/example/'
        }
      end

      before do
        stub_request(:post, "#{Settings.globus.auth_url}/v2/oauth2/token")
          .to_return(status: 200, body: token_response.to_json)

        stub_request(:post, "#{Settings.globus.transfer_url}/v0.10/operation/endpoint/#{globus_endpoint}/mkdir")
          .with(body: user_request_body.to_json)
          .to_return(status: 502, body: mkdir_response_user.to_json)

        stub_request(:post, "#{Settings.globus.transfer_url}/v0.10/operation/endpoint/#{globus_endpoint}/mkdir")
          .to_return(status: 200, body: mkdir_response.to_json)
      end

      it '#mk_dir' do
        expect { endpoint.mk_dir(sunet: user, work_id: work, version:) }.not_to raise_error
      end
    end

    context 'when another error is raised' do
      let(:user) { 'example@stanford.edu' }
      let(:work) { 'work123' }
      let(:version) { '1' }
      let(:mkdir_response_error) do
        {
          code: 'ExternalError.SomeOtherError',
          message: 'External Error',
          request_id: '1234',
          resource: '/operation/endpoint/an-endpoint-id/mkdir'
        }
      end
      let(:user_request_body) do
        {
          DATA_TYPE: 'mkdir',
          path: '/uploads/example/'
        }
      end

      before do
        stub_request(:post, "#{Settings.globus.auth_url}/v2/oauth2/token")
          .to_return(status: 200, body: token_response.to_json)

        stub_request(:post, "#{Settings.globus.transfer_url}/v0.10/operation/endpoint/#{globus_endpoint}/mkdir")
          .with(body: user_request_body.to_json)
          .to_return(status: 502, body: mkdir_response_error.to_json)

        stub_request(:post, "#{Settings.globus.transfer_url}/v0.10/operation/endpoint/#{globus_endpoint}/mkdir")
          .with(body: { DATA_TYPE: 'mkdir', path: "/uploads/example/#{work}/" }.to_json)
          .to_return(status: 200, body: mkdir_response.to_json)

        stub_request(:post, "#{Settings.globus.transfer_url}/v0.10/operation/endpoint/#{globus_endpoint}/mkdir")
          .with(body: { DATA_TYPE: 'mkdir', path: "/uploads/example/#{work}/#{version}/" }.to_json)
          .to_return(status: 200, body: mkdir_response.to_json)
      end

      it '#mk_dir' do
        expect { endpoint.mk_dir(sunet: user, work_id: work, version:) }
          .to raise_error(Globus::Client::UnexpectedResponse::EndpointError)
      end
    end
  end
end
