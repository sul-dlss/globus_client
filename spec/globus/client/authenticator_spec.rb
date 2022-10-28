# frozen_string_literal: true

RSpec.describe Globus::Client::Authenticator do
  context 'with a valid id and secret' do
    let(:client_id) { Settings.globus.client_id }
    let(:client_secret) { Settings.globus.client_secret }
    let(:globus_client) { Globus::Client.new(client_id, client_secret) }
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

    before do
      stub_request(:post, "#{Settings.globus.token_url}/v2/oauth2/token")
        .to_return(status: 200, body: token_response.to_json)
    end

    it '#token' do
      expect(globus_client.token).to eq 'a_long_silly_token'
    end
  end
end
