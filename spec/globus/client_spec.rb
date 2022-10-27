# frozen_string_literal: true

RSpec.describe Globus::Client do
  it "has a version number" do
    expect(Globus::Client::VERSION).not_to be nil
  end

  let(:client_id) { 'dummy_id' }
  let(:client_secret) { 'dummy_secret' }

  it '#initialize' do
    client = described_class.new(client_id, client_secret)
    expect(client.client_id).to eq client_id
    expect(client.client_secret).to eq client_secret
  end
end
