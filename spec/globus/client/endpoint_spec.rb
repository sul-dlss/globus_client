# frozen_string_literal: true

RSpec.describe Globus::Client::Endpoint do
  context 'with a valid token' do
    let(:client_id) { Settings.globus.client_id }
    let(:client_secret) { Settings.globus.client_secret }
    let(:globus_client) { Globus::Client.new(client_id, client_secret) }
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

    before do
      stub_request(:post, "#{Settings.globus.token_url}/v2/oauth2/token")
        .to_return(status: 200, body: token_response.to_json)

      stub_request(:get, "#{Settings.globus.transfer_url}/v0.10/operation/endpoint/#{Settings.globus.endpoint}/ls")
        .to_return(status: 200, body: list_response.to_json)
    end

    it '#list_stuff' do
      expect(endpoint.length).to eq 1
    end
  end
end
