# frozen_string_literal: true

RSpec.describe Globus::Client do
  let(:client_secret) { "dummy_secret" }
  let(:client_id) { "dummy_id" }

  it "has a version number" do
    expect(Globus::Client::VERSION).not_to be_nil
  end

  it "#initialize" do
    client = described_class.new(client_id, client_secret)
    expect(client.client_id).to eq client_id
    expect(client.client_secret).to eq client_secret
  end
end
