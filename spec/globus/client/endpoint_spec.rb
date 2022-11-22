# frozen_string_literal: true

RSpec.describe Globus::Client::Endpoint do
  subject(:endpoint) { described_class.new(config, user_id:, work_id:, work_version:) }

  let(:config) { OpenStruct.new(uploads_directory:, transfer_url:, transfer_endpoint_id:) }
  let(:transfer_endpoint_id) { "NOT_A_REAL_ENDPOINT" }
  let(:transfer_url) { "https://transfer.api.example.org" }
  let(:uploads_directory) { "/uploads/" }
  let(:user_id) { "example" }
  let(:work_id) { "123" }
  let(:work_version) { "1" }
  let(:mkdir_response) do
    {
      DATA_TYPE: "mkdir_result",
      code: "DirectoryCreated",
      message: "The directory was created successfully",
      request_id: "12345",
      resource: "/operation/endpoint/an-endpoint-identifier/mkdir"
    }
  end

  describe "#length" do
    context "when endpoint ID is found" do
      let(:list_response) do
        {
          DATA: [
            {
              DATA_TYPE: "file",
              group: "globus",
              last_modified: "2022-10-20 20:09:40+00:00",
              link_group: nil,
              link_last_modified: nil,
              link_size: nil,
              link_target: nil,
              link_user: nil,
              name: "read-test",
              permissions: "0755",
              size: 3,
              type: "dir",
              user: "globus"
            }
          ],
          DATA_TYPE: "file_list",
          absolute_path: "/",
          endpoint: transfer_endpoint_id,
          length: 1,
          path: "/~/",
          rename_supported: true,
          symlink_supported: false,
          total: 1
        }
      end

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/ls")
          .to_return(status: 200, body: list_response.to_json)
      end

      it "returns the length" do
        expect(endpoint.length).to eq 1
      end
    end

    context "when endpoint ID is not found" do
      let(:list_response) do
        {
          code: "ClientError.NotFound",
          message: "#{transfer_endpoint_id} not found.",
          request_id: "1234",
          resource: "/operation/endpoint/an-endpoint-id/ls"
        }
      end

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/ls")
          .to_return(status: 404, body: list_response.to_json)
      end

      it "raises a ResourceNotFound exception" do
        expect { endpoint.length }.to raise_error(Globus::Client::UnexpectedResponse::ResourceNotFound)
      end
    end
  end

  describe "#mkdir" do
    context "when creating a directory that does not exist" do
      before do
        stub_request(:post, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/mkdir")
          .to_return(status: 202, body: mkdir_response.to_json)
      end

      it "does not raise error" do
        expect { endpoint.mkdir }.not_to raise_error
      end
    end

    context "when creating a directory for a user that exists" do
      let(:mkdir_response_user) do
        {
          code: "ExternalError.MkdirFailed.Exists",
          message: "Path already exists, Error Path '/uploads/example/' already exists\n",
          request_id: "1234",
          resource: "/operation/endpoint/an-endpoint-id/mkdir"
        }
      end
      let(:user_request_body) do
        {
          DATA_TYPE: "mkdir",
          path: "/uploads/example/"
        }
      end

      before do
        stub_request(:post, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/mkdir")
          .with(body: user_request_body.to_json)
          .to_return(status: 502, body: mkdir_response_user.to_json)

        stub_request(:post, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/mkdir")
          .to_return(status: 200, body: mkdir_response.to_json)

        stub_request(:post, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/mkdir")
          .with(body: {DATA_TYPE: "mkdir", path: "/uploads/example/work#{work_id}/"}.to_json)
          .to_return(status: 200, body: mkdir_response.to_json)

        stub_request(:post, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/mkdir")
          .with(body: {DATA_TYPE: "mkdir", path: "/uploads/example/work#{work_id}/version#{work_version}/"}.to_json)
          .to_return(status: 200, body: mkdir_response.to_json)
      end

      it "does not raise" do
        expect { endpoint.mkdir }.not_to raise_error
      end
    end

    context "when another error is raised" do
      let(:mkdir_response_error) do
        {
          code: "ExternalError.SomeOtherError",
          message: "External Error",
          request_id: "1234",
          resource: "/operation/endpoint/an-endpoint-id/mkdir"
        }
      end
      let(:user_request_body) do
        {
          DATA_TYPE: "mkdir",
          path: "/uploads/example/"
        }
      end

      before do
        stub_request(:post, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/mkdir")
          .with(body: user_request_body.to_json)
          .to_return(status: 502, body: mkdir_response_error.to_json)

        stub_request(:post, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/mkdir")
          .with(body: {DATA_TYPE: "mkdir", path: "/uploads/example/#{work_id}/"}.to_json)
          .to_return(status: 200, body: mkdir_response.to_json)

        stub_request(:post, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/mkdir")
          .with(body: {DATA_TYPE: "mkdir", path: "/uploads/example/#{work_id}/#{work_version}/"}.to_json)
          .to_return(status: 200, body: mkdir_response.to_json)
      end

      it "raises an EndpointError" do
        expect { endpoint.mkdir }.to raise_error(Globus::Client::UnexpectedResponse::EndpointError)
      end
    end

    context "when the Globus server is under maintenance and returns a 503" do
      before do
        stub_request(:post, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/mkdir")
          .to_return(status: 503)
      end

      it "raises ServiceUnavailable" do
        expect { endpoint.mkdir }.to raise_error(Globus::Client::UnexpectedResponse::ServiceUnavailable)
      end
    end
  end

  describe "#set_permissions" do
    let(:fake_identity) do
      instance_double(Globus::Client::Identity, get_identity_id: "example")
    end

    before do
      allow(Globus::Client::Identity).to receive(:new).and_return(fake_identity)
    end

    context "when setting permissions on a directory" do
      let(:access_response) do
        {
          code: "Created",
          resource: "/endpoint/epname/access",
          DATA_TYPE: "access_create_result",
          request_id: "abc123",
          access_id: 12_345,
          message: "Access rule created successfully."
        }
      end

      before do
        stub_request(:post, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access")
          .to_return(status: 201, body: access_response.to_json)
      end

      it "does not raise an exception" do
        expect { endpoint.set_permissions }.not_to raise_error
      end
    end

    context "when re-setting permissions on a directory" do
      let(:access_response) do
        {
          code: "Exists",
          message: "This folder is already shared with this identity. If you would like to change the read/write access level, please delete this permission and then add a new permission with the desired access level.",
          request_id: "abc123",
          resource: "/endpoint/epname/access"
        }
      end

      before do
        stub_request(:post, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access")
          .to_return(status: 409, body: access_response.to_json)
      end

      it "does not raise an exception" do
        expect { endpoint.set_permissions }.not_to raise_error
      end
    end

    context "when setting permissions on an invalid directory" do
      let(:access_response) do
        {
          code: "InvalidPath",
          resource: "/endpoint/epname/access",
          DATA_TYPE: "access_create_result",
          request_id: "abc123",
          access_id: 12_345,
          message: "Invalid Path"
        }
      end

      before do
        stub_request(:post, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access")
          .to_return(status: 400, body: access_response.to_json)
      end

      it "raises a BadRequestError" do
        expect { endpoint.set_permissions }.to raise_error(Globus::Client::UnexpectedResponse::BadRequestError)
      end
    end
  end

  context "when using an invalid endpoint name" do
    let(:transfer_endpoint_id) { "not%20right" }
    let(:endpoint_response) do
      {code: "BadRequest",
       message: "Invalid endpoint name 'u_nndvljceuzcyjknli7f5t3r6ja#not right': Invalid characters",
       request_id: "ABC123",
       resource: "/operation/endpoint/not%20right/ls"}
    end

    before do
      stub_request(:post, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/mkdir")
        .to_return(status: 400, body: endpoint_response.to_json)
    end

    it "raises a BadRequestError" do
      expect { endpoint.mkdir }.to raise_error(Globus::Client::UnexpectedResponse::BadRequestError)
    end
  end

  context "when some other error not matching existing statuses occurs" do
    let(:other_response) do
      {code: "OtherError",
       message: "Some problem occurred."}
    end

    before do
      stub_request(:post, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/mkdir")
        .to_return(status: 500, body: other_response.to_json)
    end

    it "raises an UnexpectedResponse" do
      expect { endpoint.mkdir }.to raise_error(StandardError)
    end
  end
end
