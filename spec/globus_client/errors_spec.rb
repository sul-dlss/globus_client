# frozen_string_literal: true

RSpec.describe GlobusClient::Errors do
  it 'makes the base error available on the client' do
    expect(GlobusClient::Error).to eq(GlobusClient::Errors::Error)
  end
end
