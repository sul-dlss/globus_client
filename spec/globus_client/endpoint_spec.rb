# frozen_string_literal: true

RSpec.describe GlobusClient::Endpoint do
  subject(:endpoint) { described_class.new(config, user_id:, path:) }

  let(:config) { OpenStruct.new(uploads_directory:, transfer_url:, transfer_endpoint_id:) }
  let(:transfer_endpoint_id) { "NOT_A_REAL_ENDPOINT" }
  let(:transfer_url) { "https://transfer.api.example.org" }
  let(:uploads_directory) { "/uploads/" }
  let(:user_id) { "example@stanford.edu" }
  let(:path) { "example/work#{work_id}/version#{work_version}" }
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

    context "when creating a directory that already exists" do
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
          .with(body: {DATA_TYPE: "mkdir", path: "/uploads/#{path}/"}.to_json)
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
          .with(body: {DATA_TYPE: "mkdir", path: "/uploads/#{path}/"}.to_json)
          .to_return(status: 200, body: mkdir_response.to_json)
      end

      it "raises an EndpointError" do
        expect { endpoint.mkdir }.to raise_error(GlobusClient::UnexpectedResponse::EndpointError)
      end
    end

    context "when the Globus server is under maintenance and returns a 503" do
      before do
        stub_request(:post, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/mkdir")
          .to_return(status: 503)
      end

      it "raises ServiceUnavailable" do
        expect { endpoint.mkdir }.to raise_error(GlobusClient::UnexpectedResponse::ServiceUnavailable)
      end
    end
  end

  describe "#allow_writes" do
    let(:fake_identity) { instance_double(GlobusClient::Identity, get_identity_id: "example") }

    before do
      allow(GlobusClient::Identity).to receive(:new).and_return(fake_identity)
    end

    context "when no access rules are present for a directory" do
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
      let(:access_list_response) do
        {
          DATA_TYPE: "access_list",
          endpoint: transfer_endpoint_id,
          DATA: [
            {
              DATA_TYPE: "access",
              create_time: "2022-11-22T16:08:24+00:00",
              id: "e3ee1ec2-6a7f-11ed-b0bd-bfe7e7197080",
              path: "/foo/bar/",
              permissions: "rw",
              principal: "ae3e3f70-4065-408b-9cd8-39dc01b07d29",
              principal_type: "identity",
              role_id: nil,
              role_type: nil
            }
          ]
        }
      end

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access_list")
          .to_return(status: 200, body: access_list_response.to_json)
        stub_request(:post, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access")
          .to_return(status: 201, body: access_response.to_json)
      end

      it "does not raise an exception" do
        expect { endpoint.allow_writes }.not_to raise_error
      end
    end

    context "when access rules are present for a directory" do
      let(:access_response) do
        {
          code: "Updated",
          message: "Access rule '123' permissions updated successfully",
          request_id: "abc123",
          resource: "/endpoint/epname/access",
          DATA_TYPE: "result"
        }
      end
      let(:access_list_response) do
        {
          DATA_TYPE: "access_list",
          endpoint: transfer_endpoint_id,
          DATA: [
            {
              DATA_TYPE: "access",
              create_time: "2022-11-22T16:08:24+00:00",
              id: access_rule_id,
              path: "/uploads/#{path}/",
              permissions: "rw",
              principal: "ae3e3f70-4065-408b-9cd8-39dc01b07d29",
              principal_type: "identity",
              role_id: nil,
              role_type: nil
            }
          ]
        }
      end
      let(:access_rule_id) { "e3ee1ec2-6a7f-11ed-b0bd-bfe7e7197080" }

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access_list")
          .to_return(status: 200, body: access_list_response.to_json)
        stub_request(:put, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access/#{access_rule_id}")
          .to_return(status: 200, body: access_response.to_json)
      end

      it "does not raise an exception" do
        expect { endpoint.allow_writes }.not_to raise_error
      end
    end

    context "when directory is invalid" do
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
      let(:access_list_response) do
        {
          DATA_TYPE: "access_list",
          endpoint: transfer_endpoint_id,
          DATA: [
            {
              DATA_TYPE: "access",
              create_time: "2022-11-22T16:08:24+00:00",
              id: "e3ee1ec2-6a7f-11ed-b0bd-bfe7e7197080",
              path: "/foo/bar/",
              permissions: "rw",
              principal: "ae3e3f70-4065-408b-9cd8-39dc01b07d29",
              principal_type: "identity",
              role_id: nil,
              role_type: nil
            }
          ]
        }
      end

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access_list")
          .to_return(status: 200, body: access_list_response.to_json)
        stub_request(:post, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access")
          .to_return(status: 400, body: access_response.to_json)
      end

      it "raises a BadRequestError" do
        expect { endpoint.allow_writes }.to raise_error(GlobusClient::UnexpectedResponse::BadRequestError)
      end
    end
  end

  describe "#disallow_writes" do
    context "when no access rules are present for a directory" do
      let(:access_list_response) do
        {
          DATA_TYPE: "access_list",
          endpoint: transfer_endpoint_id,
          DATA: [
            {
              DATA_TYPE: "access",
              create_time: "2022-11-22T16:08:24+00:00",
              id: "e3ee1ec2-6a7f-11ed-b0bd-bfe7e7197080",
              path: "/foo/bar/",
              permissions: "rw",
              principal: "ae3e3f70-4065-408b-9cd8-39dc01b07d29",
              principal_type: "identity",
              role_id: nil,
              role_type: nil
            }
          ]
        }
      end

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access_list")
          .to_return(status: 200, body: access_list_response.to_json)
      end

      it "raises an exception" do
        expect { endpoint.disallow_writes }.to raise_error(StandardError)
      end
    end

    context "when access rules are present for a directory" do
      let(:access_response) do
        {
          code: "Updated",
          message: "Access rule '123' permissions updated successfully",
          request_id: "abc123",
          resource: "/endpoint/epname/access",
          DATA_TYPE: "result"
        }
      end
      let(:access_list_response) do
        {
          DATA_TYPE: "access_list",
          endpoint: transfer_endpoint_id,
          DATA: [
            {
              DATA_TYPE: "access",
              create_time: "2022-11-22T16:08:24+00:00",
              id: access_rule_id,
              path: "/uploads/#{path}/",
              permissions: "rw",
              principal: "ae3e3f70-4065-408b-9cd8-39dc01b07d29",
              principal_type: "identity",
              role_id: nil,
              role_type: nil
            }
          ]
        }
      end
      let(:access_rule_id) { "e3ee1ec2-6a7f-11ed-b0bd-bfe7e7197080" }

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access_list")
          .to_return(status: 200, body: access_list_response.to_json)
        stub_request(:put, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access/#{access_rule_id}")
          .to_return(status: 200, body: access_response.to_json)
      end

      it "does not raise an exception" do
        expect { endpoint.disallow_writes }.not_to raise_error
      end
    end

    context "when Globus returns an error" do
      let(:access_list_response) do
        {
          DATA_TYPE: "access_list",
          endpoint: transfer_endpoint_id,
          DATA: [
            {
              DATA_TYPE: "access",
              create_time: "2022-11-22T16:08:24+00:00",
              id: access_rule_id,
              path: "/uploads/#{path}/",
              permissions: "rw",
              principal: "ae3e3f70-4065-408b-9cd8-39dc01b07d29",
              principal_type: "identity",
              role_id: nil,
              role_type: nil
            }
          ]
        }
      end
      let(:access_rule_id) { "e3ee1ec2-6a7f-11ed-b0bd-bfe7e7197080" }

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access_list")
          .to_return(status: 200, body: access_list_response.to_json)
        stub_request(:put, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access/#{access_rule_id}")
          .to_return(status: 503)
      end

      it "raises ServiceUnavailable" do
        expect { endpoint.disallow_writes }.to raise_error(GlobusClient::UnexpectedResponse::ServiceUnavailable)
      end
    end
  end

  describe "#delete_access_rule" do
    let(:user_id) { nil }

    context "when access rule is present for directory" do
      let(:access_list_response) do
        {
          DATA_TYPE: "access_list",
          endpoint: transfer_endpoint_id,
          DATA: [
            {
              DATA_TYPE: "access",
              create_time: "2022-11-22T16:08:24+00:00",
              id: access_rule_id,
              path: "/uploads/#{path}/",
              permissions: "rw",
              principal: "ae3e3f70-4065-408b-9cd8-39dc01b07d29",
              principal_type: "identity",
              role_id: nil,
              role_type: nil
            }
          ]
        }
      end
      let(:delete_access_rule_response) do
        {
          message: "Access rule #{access_rule_id} deleted successfully",
          code: "Deleted",
          resource: "/endpoint/user#ep1/access/123",
          DATA_TYPE: "result",
          request_id: "ABCdef789"
        }
      end
      let(:access_rule_id) { "e3ee1ec2-6a7f-11ed-b0bd-bfe7e7197080" }

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access_list")
          .to_return(status: 200, body: access_list_response.to_json)
        stub_request(:delete, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access/#{access_rule_id}")
          .to_return(status: 200, body: delete_access_rule_response.to_json)
      end

      it "does not raise an exception" do
        expect { endpoint.delete_access_rule }.not_to raise_error
      end
    end

    context "when no access rules are present for directory" do
      let(:access_list_response) do
        {
          DATA_TYPE: "access_list",
          endpoint: transfer_endpoint_id,
          DATA: [
            {
              DATA_TYPE: "access",
              create_time: "2022-11-22T16:08:24+00:00",
              id: "e3ee1ec2-6a7f-11ed-b0bd-bfe7e7197080",
              path: "/foo/bar/",
              permissions: "rw",
              principal: "ae3e3f70-4065-408b-9cd8-39dc01b07d29",
              principal_type: "identity",
              role_id: nil,
              role_type: nil
            }
          ]
        }
      end

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access_list")
          .to_return(status: 200, body: access_list_response.to_json)
      end

      it "does raises an exception" do
        expect { endpoint.delete_access_rule }.to raise_error(StandardError)
      end
    end

    context "when Globus returns an error" do
      let(:access_list_response) do
        {
          DATA_TYPE: "access_list",
          endpoint: transfer_endpoint_id,
          DATA: [
            {
              DATA_TYPE: "access",
              create_time: "2022-11-22T16:08:24+00:00",
              id: access_rule_id,
              path: "/uploads/#{path}/",
              permissions: "rw",
              principal: "ae3e3f70-4065-408b-9cd8-39dc01b07d29",
              principal_type: "identity",
              role_id: nil,
              role_type: nil
            }
          ]
        }
      end
      let(:access_rule_id) { "e3ee1ec2-6a7f-11ed-b0bd-bfe7e7197080" }

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access_list")
          .to_return(status: 200, body: access_list_response.to_json)
        stub_request(:delete, "#{config.transfer_url}/v0.10/endpoint/#{transfer_endpoint_id}/access/#{access_rule_id}")
          .to_return(status: 503)
      end

      it "raises ServiceUnavailable" do
        expect { endpoint.delete_access_rule }.to raise_error(GlobusClient::UnexpectedResponse::ServiceUnavailable)
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
      expect { endpoint.mkdir }.to raise_error(GlobusClient::UnexpectedResponse::BadRequestError)
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

  context "when the token needs to be refreshed" do
    before do
      stub_request(:post, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/mkdir")
        .to_return(status: 401, body: {}.to_json)
    end

    it "raises an UnexpectedResponse" do
      expect { endpoint.mkdir }.to raise_error(GlobusClient::UnexpectedResponse::UnauthorizedError)
    end
  end

  describe "#has_files?" do
    let(:path) { "example/work123/version1" }
    let(:list_response1) do
      {DATA: [{DATA_TYPE: "file",
               group: "globus",
               last_modified: "2022-12-07 19:23:33+00:00",
               link_group: nil,
               link_last_modified: nil,
               link_size: nil,
               link_target: nil,
               link_user: nil,
               name: "data",
               permissions: "0755",
               size: 3,
               type: "dir",
               user: "globus"},
        {DATA_TYPE: "file",
         group: "globus",
         last_modified: "2022-12-07 19:23:33+00:00",
         link_group: nil,
         link_last_modified: nil,
         link_size: nil,
         link_target: nil,
         link_user: nil,
         name: "outputs",
         permissions: "0755",
         size: 3,
         type: "dir",
         user: "globus"},
        {DATA_TYPE: "file",
         group: "globus",
         last_modified: "2022-12-07 22:41:54+00:00",
         link_group: nil,
         link_last_modified: nil,
         link_size: nil,
         link_target: nil,
         link_user: nil,
         name: "README.txt",
         permissions: "0644",
         size: 10,
         type: "file",
         user: "globus"}],
       DATA_TYPE: "file_list",
       absolute_path: "/uploads/example/work1234/version1/",
       endpoint: "e32f7087-d32d-4588-8517-b2d0d32d53b8",
       length: 1,
       path: "/uploads/example/work1234/version1/",
       rename_supported: true,
       symlink_supported: false,
       total: 2}
    end
    let(:list_path2) { "example/work123/version1/data" }
    let(:list_response2) do
      {DATA: [{DATA_TYPE: "file",
               group: "globus",
               last_modified: "2022-12-07 19:23:33+00:00",
               link_group: nil,
               link_last_modified: nil,
               link_size: nil,
               link_target: nil,
               link_user: nil,
               name: "test.txt",
               permissions: "0755",
               size: 3,
               type: "file",
               user: "globus"}],
       DATA_TYPE: "file_list",
       absolute_path: "/uploads/example/work123/version1/data/",
       endpoint: "1234",
       length: 1,
       path: "/uploads/example/work123/version1/data/",
       total: 1}
    end
    let(:list_path3) { "example/work123/version1/outputs" }
    let(:list_response3) do
      {DATA: [{DATA_TYPE: "file",
               group: "globus",
               last_modified: "2022-12-07 19:23:33+00:00",
               link_group: nil,
               link_last_modified: nil,
               link_size: nil,
               link_target: nil,
               link_user: nil,
               name: "output.txt",
               permissions: "0755",
               size: 3,
               type: "file",
               user: "globus"}],
       DATA_TYPE: "file_list",
       absolute_path: "/uploads/example/work123/version1/outputs/",
       endpoint: "1234",
       length: 1,
       path: "/uploads/example/work123/version1/outputs/",
       total: 1}
    end

    context "when path is empty" do
      let(:empty_response) do
        {DATA: [],
         DATA_TYPE: "file_list",
         absolute_path: "/uploads/example/work1234/version1/",
         endpoint: "e32f7087-d32d-4588-8517-b2d0d32d53b8",
         length: 0,
         path: "/uploads/example/work1234/version1/",
         rename_supported: true,
         symlink_supported: false,
         total: 0}
      end

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/ls?path=/uploads/#{path}/")
          .to_return(status: 200, body: empty_response.to_json)
      end

      it "returns false" do
        expect(endpoint).not_to have_files
      end
    end

    context "when path has one or more empty subdirectories" do
      let(:empty_response) do
        {DATA: [],
         DATA_TYPE: "file_list",
         absolute_path: "/uploads/example/work1234/version1/data/",
         endpoint: "e32f7087-d32d-4588-8517-b2d0d32d53b8",
         length: 0,
         path: "/uploads/example/work1234/version1/data/",
         rename_supported: true,
         symlink_supported: false,
         total: 0}
      end
      let(:single_directory_response) do
        {DATA: [{DATA_TYPE: "file",
                 group: "globus",
                 last_modified: "2022-12-07 19:23:33+00:00",
                 link_group: nil,
                 link_last_modified: nil,
                 link_size: nil,
                 link_target: nil,
                 link_user: nil,
                 name: "data",
                 permissions: "0755",
                 size: 0,
                 type: "dir",
                 user: "globus"}],
         DATA_TYPE: "file_list",
         absolute_path: "/uploads/example/work1234/version1/",
         endpoint: "e32f7087-d32d-4588-8517-b2d0d32d53b8",
         length: 1,
         path: "/uploads/example/work1234/version1/",
         rename_supported: true,
         symlink_supported: false,
         total: 1}
      end

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/ls?path=/uploads/#{path}/")
          .to_return(status: 200, body: single_directory_response.to_json)
        stub_request(:get, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/ls?path=/uploads/#{path}/data/")
          .to_return(status: 200, body: empty_response.to_json)
      end

      it "returns false" do
        expect(endpoint).not_to have_files
      end
    end

    context "when path has a file" do
      let(:single_file_response) do
        {DATA: [{DATA_TYPE: "file",
                 group: "globus",
                 last_modified: "2022-12-07 19:23:33+00:00",
                 link_group: nil,
                 link_last_modified: nil,
                 link_size: nil,
                 link_target: nil,
                 link_user: nil,
                 name: "README.txt",
                 permissions: "0755",
                 size: 3,
                 type: "file",
                 user: "globus"}],
         DATA_TYPE: "file_list",
         absolute_path: "/uploads/example/work1234/version1/",
         endpoint: "e32f7087-d32d-4588-8517-b2d0d32d53b8",
         length: 1,
         path: "/uploads/example/work1234/version1/",
         rename_supported: true,
         symlink_supported: false,
         total: 1}
      end

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/ls?path=/uploads/#{path}/")
          .to_return(status: 200, body: single_file_response.to_json)
      end

      it "returns true" do
        expect(endpoint).to have_files
      end
    end

    context "when path has a file in one or more subdirectories" do
      let(:single_directory_response) do
        {DATA: [{DATA_TYPE: "file",
                 group: "globus",
                 last_modified: "2022-12-07 19:23:33+00:00",
                 link_group: nil,
                 link_last_modified: nil,
                 link_size: nil,
                 link_target: nil,
                 link_user: nil,
                 name: "data",
                 permissions: "0755",
                 size: 0,
                 type: "dir",
                 user: "globus"}],
         DATA_TYPE: "file_list",
         absolute_path: "/uploads/example/work1234/version1/",
         endpoint: "e32f7087-d32d-4588-8517-b2d0d32d53b8",
         length: 1,
         path: "/uploads/example/work1234/version1/",
         rename_supported: true,
         symlink_supported: false,
         total: 1}
      end
      let(:single_file_response) do
        {DATA: [{DATA_TYPE: "file",
                 group: "globus",
                 last_modified: "2022-12-07 19:23:33+00:00",
                 link_group: nil,
                 link_last_modified: nil,
                 link_size: nil,
                 link_target: nil,
                 link_user: nil,
                 name: "README.txt",
                 permissions: "0755",
                 size: 3,
                 type: "file",
                 user: "globus"}],
         DATA_TYPE: "file_list",
         absolute_path: "/uploads/example/work1234/version1/data/",
         endpoint: "e32f7087-d32d-4588-8517-b2d0d32d53b8",
         length: 1,
         path: "/uploads/example/work1234/version1/data/",
         rename_supported: true,
         symlink_supported: false,
         total: 1}
      end

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/ls?path=/uploads/#{path}/")
          .to_return(status: 200, body: single_directory_response.to_json)
        stub_request(:get, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/ls?path=/uploads/#{path}/data/")
          .to_return(status: 200, body: single_file_response.to_json)
      end

      it "returns true" do
        expect(endpoint).to have_files
      end
    end
  end

  describe "#list_files" do
    context "with an unsplittable (e.g., nil) path" do
      let(:path) { nil }

      it "raises an ArgumentError" do
        expect { endpoint.list_files }.to raise_error(ArgumentError, /Unexpected path provided: nil/)
      end
    end

    context "with a path that does not exist" do
      let(:path) { "example/non-existent-work/version1" }
      let(:not_found_response) do
        {code: "ClientError.NotFound",
         message: "Directory '#{path}' not found on endpoint"}
      end

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/ls?path=/uploads/#{path}/")
          .to_return(status: 404, body: not_found_response.to_json)
      end

      it "raises an UnexpectedResponse" do
        expect { endpoint.list_files }.to raise_error(GlobusClient::UnexpectedResponse::ResourceNotFound)
      end
    end

    context "with a path that exists" do
      let(:path) { "example/work123/version1" }
      let(:list_response1) do
        {DATA: [{DATA_TYPE: "file",
                 group: "globus",
                 last_modified: "2022-12-07 19:23:33+00:00",
                 link_group: nil,
                 link_last_modified: nil,
                 link_size: nil,
                 link_target: nil,
                 link_user: nil,
                 name: "data",
                 permissions: "0755",
                 size: 3,
                 type: "dir",
                 user: "globus"},
          {DATA_TYPE: "file",
           group: "globus",
           last_modified: "2022-12-07 19:23:33+00:00",
           link_group: nil,
           link_last_modified: nil,
           link_size: nil,
           link_target: nil,
           link_user: nil,
           name: "outputs",
           permissions: "0755",
           size: 3,
           type: "dir",
           user: "globus"},
          {DATA_TYPE: "file",
           group: "globus",
           last_modified: "2022-12-07 22:41:54+00:00",
           link_group: nil,
           link_last_modified: nil,
           link_size: nil,
           link_target: nil,
           link_user: nil,
           name: "README.txt",
           permissions: "0644",
           size: 10,
           type: "file",
           user: "globus"}],
         DATA_TYPE: "file_list",
         absolute_path: "/uploads/example/work1234/version1/",
         endpoint: "e32f7087-d32d-4588-8517-b2d0d32d53b8",
         length: 1,
         path: "/uploads/example/work1234/version1/",
         rename_supported: true,
         symlink_supported: false,
         total: 2}
      end
      let(:list_path2) { "example/work123/version1/data" }
      let(:list_response2) do
        {DATA: [{DATA_TYPE: "file",
                 group: "globus",
                 last_modified: "2022-12-07 19:23:33+00:00",
                 link_group: nil,
                 link_last_modified: nil,
                 link_size: nil,
                 link_target: nil,
                 link_user: nil,
                 name: "test.txt",
                 permissions: "0755",
                 size: 3,
                 type: "file",
                 user: "globus"}],
         DATA_TYPE: "file_list",
         absolute_path: "/uploads/example/work123/version1/data/",
         endpoint: "1234",
         length: 1,
         path: "/uploads/example/work123/version1/data/",
         total: 1}
      end
      let(:list_path3) { "example/work123/version1/outputs" }
      let(:list_response3) do
        {DATA: [{DATA_TYPE: "file",
                 group: "globus",
                 last_modified: "2022-12-07 19:23:33+00:00",
                 link_group: nil,
                 link_last_modified: nil,
                 link_size: nil,
                 link_target: nil,
                 link_user: nil,
                 name: "output.txt",
                 permissions: "0755",
                 size: 3,
                 type: "file",
                 user: "globus"}],
         DATA_TYPE: "file_list",
         absolute_path: "/uploads/example/work123/version1/outputs/",
         endpoint: "1234",
         length: 1,
         path: "/uploads/example/work123/version1/outputs/",
         total: 1}
      end
      let(:filelist) do
        [
          described_class::FileInfo.new("/uploads/example/work123/version1/README.txt", 10),
          described_class::FileInfo.new("/uploads/example/work123/version1/data/test.txt", 3),
          described_class::FileInfo.new("/uploads/example/work123/version1/outputs/output.txt", 3)
        ]
      end

      before do
        stub_request(:get, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/ls?path=/uploads/#{path}/")
          .to_return(status: 200, body: list_response1.to_json)
        stub_request(:get, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/ls?path=/uploads/#{list_path2}/")
          .to_return(status: 200, body: list_response2.to_json)
        stub_request(:get, "#{config.transfer_url}/v0.10/operation/endpoint/#{transfer_endpoint_id}/ls?path=/uploads/#{list_path3}/")
          .to_return(status: 200, body: list_response3.to_json)
      end

      it "returns a list of FileInfo instances" do
        expect(endpoint.list_files).to eq(filelist)
      end
    end
  end
end
