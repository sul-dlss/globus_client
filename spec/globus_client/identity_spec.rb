# frozen_string_literal: true

RSpec.describe GlobusClient::Identity do
  subject(:identity) { described_class.new(config) }

  let(:auth_url) { "https://auth.example.org" }
  let(:client_id) { "client_id" }
  let(:client_secret) { "client_secret" }
  let(:config) { OpenStruct.new(auth_url:) }
  let(:user_id) { "example@stanford.edu" }
  let(:token_response) do
    {
      access_token: "a_long_silly_token",
      scope: "urn:globus:auth:scope:transfer.api.globus.org:all",
      expires_in: 172_800,
      token_type: "Bearer",
      resource_server: "transfer.api.globus.org",
      other_tokens: []
    }
  end

  context "with a valid Globus ID" do
    let(:identity_response) do
      {
        identities: [{
          name: "Jane Tester",
          email: user_id,
          id: "12345abc",
          organization: "Stanford University",
          identity_type: "login",
          username: user_id,
          identity_provider: "example-identity-provider",
          status: "used"
        }]
      }
    end

    before do
      stub_request(:post, "#{auth_url}/v2/oauth2/token")
        .to_return(status: 200, body: token_response.to_json)

      stub_request(:get, "#{auth_url}/v2/api/identities?usernames=#{user_id}")
        .to_return(status: 200, body: identity_response.to_json)
    end

    describe "#get_identity_id" do
      it "returns the globus user ID" do
        expect(identity.get_identity_id(user_id)).to eq "12345abc"
      end
    end

    describe "#exists?" do
      it "indicates that the user exists" do
        expect(identity.exists?(user_id)).to be true
      end
    end
  end

  context "with user not existing in Globus" do
    let(:identity_response) do
      {
        identities: [{
          name: "None",
          email: "None",
          id: "12345abc",
          organization: "None",
          identity_type: "None",
          username: user_id,
          identity_provider: "example-identity-provider",
          status: "unused"
        }]
      }
    end

    before do
      stub_request(:post, "#{auth_url}/v2/oauth2/token")
        .to_return(status: 200, body: token_response.to_json)

      stub_request(:get, "#{auth_url}/v2/api/identities?usernames=#{user_id}")
        .to_return(status: 200, body: identity_response.to_json)
    end

    describe "#get_identity_id" do
      it "raises an error" do
        expect { identity.get_identity_id(user_id) }.to raise_error(RuntimeError, /No matching active Globus user found/)
      end
    end

    describe "#exists?" do
      it "indicates that the user does not exist" do
        expect(identity.exists?(user_id)).to be false
      end
    end
  end

  context "when API returns a 403" do
    # Example from https://docs.globus.org/api/search/errors/
    let(:identity_response) do
      {
        code: "AccessForbidden.NeedsOwner",
        message: 'The operation you have requested requires "Owner" rights',
        status: 403,
        error_data: [
          {
            code: "AccessForbidden.NeedsOwner",
            message: "You are not permitted to FOO a BAR which you do not own"
          }
        ]
      }
    end

    before do
      stub_request(:post, "#{auth_url}/v2/oauth2/token")
        .to_return(status: 200, body: token_response.to_json)

      stub_request(:get, "#{auth_url}/v2/api/identities?usernames=#{user_id}")
        .to_return(status: 403, body: identity_response.to_json)
    end

    it "raises a ForbiddenError" do
      expect { identity.get_identity_id(user_id) }.to raise_error(GlobusClient::UnexpectedResponse::ForbiddenError)
    end
  end

  context "when API returns a 401" do
    let(:identity_response) do
      {errors:
        [{detail: "Call must be authenticated",
          code: "UNAUTHORIZED",
          title: "Unauthorized",
          id: "1234-abcd-01234",
          status: "401"}],
       error: "unauthorized",
       error_description: "Unauthorized"}
    end

    before do
      stub_request(:post, "#{auth_url}/v2/oauth2/token")
        .to_return(status: 200, body: token_response.to_json)

      stub_request(:get, "#{auth_url}/v2/api/identities?usernames=#{user_id}")
        .to_return(status: 401, body: identity_response.to_json)
    end

    describe "#get_identity_id" do
      it "raises an UnauthorizedError" do
        expect { identity.get_identity_id(user_id) }.to raise_error(GlobusClient::UnexpectedResponse::UnauthorizedError)
      end
    end

    describe "#exists?" do
      it "raises an UnauthorizedError" do
        expect { identity.exists?(user_id) }.to raise_error(GlobusClient::UnexpectedResponse::UnauthorizedError)
      end
    end
  end
end
