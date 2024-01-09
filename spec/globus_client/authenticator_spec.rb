# frozen_string_literal: true

RSpec.describe GlobusClient::Authenticator do
  let(:auth_url) { 'https://auth.example.org' }
  let(:client_id) { 'client_id' }
  let(:client_secret) { 'client_secret' }
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
    stub_request(:post, "#{auth_url}/v2/oauth2/token")
      .to_return(status: 200, body: token_response.to_json)
  end

  describe '.token' do
    let(:instance) do
      described_class.new
    end

    before do
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:token)
    end

    it 'invokes #token on a new instance' do
      described_class.token
      expect(instance).to have_received(:token).once
    end
  end

  describe '#token' do
    subject(:authenticator) { described_class.new }

    before do
      GlobusClient.configure(
        auth_url:,
        client_id:,
        client_secret:,
        transfer_endpoint_id: 'not_a_real_endpoint',
        uploads_directory: '/fake_uploads/'
      )
    end

    it 'parses the token from the response' do
      expect(authenticator.token).to eq 'a_long_silly_token'
    end
  end
end
