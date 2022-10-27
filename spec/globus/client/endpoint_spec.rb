# frozen_string_literal: true

RSpec.describe Globus::Client::Endpoint do
  context 'with a valid token' do
    let(:client_id) { '' }
    let(:client_secret) { '' }
    let(:globus_client) { Globus::Client.new(client_id, client_secret) }
    let(:endpoint_connection) { described_class.new(globus_client.token) }

    it '#list_stuff' do
      expect(endpoint_connection.list_stuff).to eq ''
    end
  end
end