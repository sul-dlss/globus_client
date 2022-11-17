# frozen_string_literal: true

RSpec.describe Globus::Client do
  subject(:client) { described_class.new(client_id, client_secret) }

  let(:client_secret) { "dummy_secret" }
  let(:client_id) { "dummy_id" }

  it "has a version number" do
    expect(Globus::Client::VERSION).not_to be_nil
  end

  it "has a client_id attr" do
    expect(client.client_id).to eq(client_id)
  end

  it "has a client_secret attr" do
    expect(client.client_secret).to eq(client_secret)
  end
end
