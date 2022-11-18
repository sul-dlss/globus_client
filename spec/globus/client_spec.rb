# frozen_string_literal: true

RSpec.describe Globus::Client do
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
    expect(Globus::Client::VERSION).not_to be_nil
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

  describe "#mkdir" do
    before do
      allow(described_class::Endpoint).to receive(:new).and_return(fake_endpoint)
    end

    let(:fake_endpoint) { instance_double(described_class::Endpoint, mkdir: nil, set_permissions: nil) }
    let(:user_id) { "mjgiarlo" }
    let(:work_id) { 1234 }
    let(:work_version) { 2 }

    it "invokes mkdir on the Endpoint class, injecting config" do
      client.mkdir(user_id:, work_id:, work_version:)
      expect(fake_endpoint).to have_received(:mkdir).once
    end
  end

  describe ".mkdir" do
    before do
      allow(described_class::Endpoint).to receive(:new).and_return(fake_endpoint)
    end

    let(:fake_endpoint) { instance_double(described_class::Endpoint, mkdir: nil, set_permissions: nil) }
    let(:user_id) { "mjgiarlo" }
    let(:work_id) { 1234 }
    let(:work_version) { 2 }

    it "invokes mkdir on the Endpoint class, injecting config" do
      described_class.mkdir(user_id:, work_id:, work_version:)
      expect(fake_endpoint).to have_received(:mkdir).once
    end
  end
end
