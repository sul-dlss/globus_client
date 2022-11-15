# frozen_string_literal: true

RSpec.describe Globus::Client::Identity do
  let(:client_id) { Settings.globus.client_id }
  let(:client_secret) { Settings.globus.client_secret }
  let(:globus_client) { Globus::Client.new(client_id, client_secret) }
  let(:identity) { described_class.new(globus_client.token) }
  let(:email) { 'example@stanford.edu' }
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

  context 'with a valid sunet email' do
    let(:identity_response) do
      {
        'identities': [{
          'name': 'Jane Tester',
          'email': 'example@stanford.edu',
          'id': '12345abc',
          'organization': 'Stanford University',
          'identity_type': 'login',
          'username': 'example@stanford.edu',
          'identity_provider': 'example-identity-provider',
          'status': 'used'
        }]
      }
    end

    before do
      stub_request(:post, "#{Settings.globus.auth_url}/v2/oauth2/token")
        .to_return(status: 200, body: token_response.to_json)

      stub_request(:get, "#{Settings.globus.auth_url}/v2/api/identities?usernames=example@stanford.edu")
        .to_return(status: 200, body: identity_response.to_json)
    end

    it '#get_identity' do
      expect(identity.get_identity_id(email)).to eq '12345abc'
    end
  end

  context 'with an invalid sunet email' do
    let(:email) { 'example@example.com' }
    let(:identity_response) do
      {
        'identities': [{
          'name': 'Jane Tester',
          'email': 'example@example.com',
          'id': '12345abc',
          'organization': 'Stanford University',
          'identity_type': 'login',
          'username': 'example@example.com',
          'identity_provider': 'example-identity-provider',
          'status': 'used'
        }]
      }
    end

    before do
      stub_request(:post, "#{Settings.globus.auth_url}/v2/oauth2/token")
        .to_return(status: 200, body: token_response.to_json)
    end

    it '#get_identity' do
      expect { identity.get_identity_id(email) }.to raise_error(StandardError)
    end
  end

  context 'with user not active in Globus' do
    let(:identity_response) do
      {
        'identities': [{
          'name': 'Jane Tester',
          'email': 'example@stanford.edu',
          'id': '12345abc',
          'organization': 'Stanford University',
          'identity_type': 'login',
          'username': 'example@stanford.edu',
          'identity_provider': 'example-identity-provider',
          'status': 'unused'
        }]
      }
    end

    before do
      stub_request(:post, "#{Settings.globus.auth_url}/v2/oauth2/token")
        .to_return(status: 200, body: token_response.to_json)

      stub_request(:get, "#{Settings.globus.auth_url}/v2/api/identities?usernames=example@stanford.edu")
        .to_return(status: 200, body: identity_response.to_json)
    end

    it '#get_identity' do
      expect { identity.get_identity_id(email) }.to raise_error(StandardError)
    end
  end

  context 'when API returns a 403' do
    # Example from https://docs.globus.org/api/search/errors/
    let(:identity_response) do
      {
        'code': 'AccessForbidden.NeedsOwner',
        'message': 'The operation you have requested requires "Owner" rights',
        'status': 403,
        'error_data': [
          {
            'code': 'AccessForbidden.NeedsOwner',
            'message': 'You are not permitted to FOO a BAR which you do not own'
          }
        ]
      }
    end

    before do
      stub_request(:post, "#{Settings.globus.auth_url}/v2/oauth2/token")
        .to_return(status: 200, body: token_response.to_json)

      stub_request(:get, "#{Settings.globus.auth_url}/v2/api/identities?usernames=example@stanford.edu")
        .to_return(status: 403, body: identity_response.to_json)
    end

    it 'raises a ForbiddenError' do
      expect { identity.get_identity_id(email) }.to raise_error(Globus::Client::UnexpectedResponse::ForbiddenError)
    end
  end
end
