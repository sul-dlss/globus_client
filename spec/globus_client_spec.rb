# frozen_string_literal: true

RSpec.describe GlobusClient do
  subject(:client) do
    described_class.configure(**args)
  end

  let(:args) do
    {
      client_id:,
      client_secret:,
      uploads_directory:,
      transfer_endpoint_id:
    }
  end
  let(:client_id) { "dummy_id" }
  let(:client_secret) { "dummy_secret" }
  let(:transfer_endpoint_id) { "NOT_A_REAL_ENDPOINT" }
  let(:uploads_directory) { "/uploads/" }

  before do
    stub_request(:post, "#{described_class.default_auth_url}/v2/oauth2/token")
      .to_return(status: 200, body: "{}")
  end

  it "has a version number" do
    expect(GlobusClient::VERSION).not_to be_nil
  end

  it "has singleton behavior" do
    expect(described_class.instance).to be_a(described_class)
  end

  describe ".configure" do
    context "when auth_url and transfer_url are supplied" do
      let(:args) do
        {
          client_id:,
          client_secret:,
          uploads_directory:,
          transfer_endpoint_id:,
          auth_url:,
          transfer_url:
        }
      end
      let(:auth_url) { "https://globus.example.org" }
      let(:transfer_url) { "https://globus.example.org/transfer" }

      before do
        stub_request(:post, "#{auth_url}/v2/oauth2/token")
          .to_return(status: 200, body: "{}")
      end

      it "uses the supplied auth_url value" do
        expect(client.config.auth_url).to eq(auth_url)
      end

      it "uses the supplied transfer_url value" do
        expect(client.config.transfer_url).to eq(transfer_url)
      end
    end
  end

  describe "#config" do
    it "includes a token" do
      expect(client.config.token).to be_nil
    end

    it "includes an uploads directory" do
      expect(client.config.uploads_directory).to eq(uploads_directory)
    end

    it "includes a transfer endpoint id" do
      expect(client.config.transfer_endpoint_id).to eq(transfer_endpoint_id)
    end

    it "includes a auth url" do
      expect(client.config.auth_url).to eq(described_class.default_auth_url)
    end

    it "includes a transfer url" do
      expect(client.config.transfer_url).to eq(described_class.default_transfer_url)
    end
  end

  describe ".user_exists?" do
    let(:fake_instance) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:instance).and_return(fake_instance)
      allow(fake_instance).to receive(:user_exists?)
    end

    it "invokes instance#user_exists?" do
      described_class.user_exists?
      expect(fake_instance).to have_received(:user_exists?).once
    end
  end

  describe "#user_exists?" do
    context "when request is successful" do
      let(:fake_identity) { instance_double(described_class::Identity, exists?: nil) }

      before do
        allow(described_class::Identity).to receive(:new).and_return(fake_identity)
        allow(fake_identity).to receive(:exists?)
      end

      it "invokes Identity#exists?" do
        client.user_exists?(sunetid: "bogus")
        expect(fake_identity).to have_received(:exists?).once
      end
    end

    # Tests the TokenWrapper that requests a new token, with a method that might first encounter the error
    context "when token is expired" do
      let(:fake_identity) { instance_double(described_class::Identity, exists?: nil) }

      before do
        allow(described_class::Identity).to receive(:new).and_return(fake_identity)
        allow(GlobusClient::Authenticator).to receive(:token).and_return("a_token", "new_token")
        allow(fake_identity).to receive(:exists?).once.and_raise(GlobusClient::UnexpectedResponse::UnauthorizedError)
        allow(fake_identity).to receive(:exists?).once.and_return(true)
      end

      it "retries Identity#exists?" do
        expect(client.user_exists?(sunetid: "user")).to be true
      end
    end

    context "when UnauthorizedError raised again upon retry" do
      let(:fake_identity) { instance_double(described_class::Identity, exists?: nil) }

      before do
        allow(described_class::Identity).to receive(:new).and_return(fake_identity)
        allow(GlobusClient::Authenticator).to receive(:token).and_return("a_token", "new_token")
        allow(fake_identity).to receive(:exists?).and_raise(GlobusClient::UnexpectedResponse::UnauthorizedError)
      end

      it "raises an error with Identity#exists?" do
        expect { client.user_exists?(sunetid: "bogus") }.to raise_error(GlobusClient::UnexpectedResponse::UnauthorizedError)
      end
    end
  end

  # Test public API methods in the client that are facades in front of `Endpoint#list_files`
  [:file_count, :get_filenames, :total_size].each do |method|
    describe ".#{method}" do
      let(:fake_instance) { instance_double(described_class) }

      before do
        allow(described_class).to receive(:instance).and_return(fake_instance)
        allow(fake_instance).to receive(method)
      end

      it "invokes instance##{method}" do
        described_class.public_send(method)
        expect(fake_instance).to have_received(method).once
      end
    end

    describe "##{method}" do
      let(:fake_endpoint) { instance_double(described_class::Endpoint, list_files: nil) }

      before do
        allow(described_class::Endpoint).to receive(:new).and_return(fake_endpoint)
        allow(fake_endpoint).to receive(:list_files)
      end

      it "invokes Endpoint#list_files" do
        client.public_send(method, path: "foo/bar/")
        expect(fake_endpoint).to have_received(:list_files).once
      end
    end
  end

  # Test public API methods in the client that are sent to the Endpoint using the same names
  [:disallow_writes, :has_files?, :list_files, :mkdir].each do |method|
    describe ".#{method}" do
      let(:fake_instance) { instance_double(described_class) }

      before do
        allow(described_class).to receive(:instance).and_return(fake_instance)
        allow(fake_instance).to receive(method)
      end

      it "invokes instance##{method}" do
        described_class.public_send(method)
        expect(fake_instance).to have_received(method).once
      end
    end

    describe "##{method}" do
      let(:fake_endpoint) { instance_double(described_class::Endpoint, allow_writes: nil) }

      before do
        allow(described_class::Endpoint).to receive(:new).and_return(fake_endpoint)
        allow(fake_endpoint).to receive(method)
      end

      it "invokes Endpoint##{method}" do
        client.public_send(method)
        expect(fake_endpoint).to have_received(method).once
      end
    end
  end
end
