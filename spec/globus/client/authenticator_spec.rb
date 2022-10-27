# frozen_string_literal: true

RSpec.describe Globus::Client::Authenticator do
  context 'with a valid id and secret' do
    let(:client_id) { '' }
    let(:client_secret) { '' }
    let(:globus_client) { Globus::Client.new(client_id, client_secret) }

    it '#token' do
      expect(globus_client.token).to eq ''
    end
  end
end