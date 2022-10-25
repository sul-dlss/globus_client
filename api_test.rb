# frozen_string_literal: true

require 'faraday'
require 'byebug'

CLIENT_ID = ''
CLIENT_SECRET = ''
ENDPOINT_ID = '34ea3e65-6831-479a-8da3-87f118e3fc2b'

# Request an access_token
form_data = { 'client_id': CLIENT_ID,
              'client_secret': CLIENT_SECRET,
              'encoding': 'form',
              'grant_type': 'client_credentials',
              'scope': 'urn:globus:auth:scope:transfer.api.globus.org:all' }

auth_url = 'https://auth.globus.org/'
conn = Faraday.new(
  url: auth_url
)

response = conn.post('/v2/oauth2/token', form_data)
token = JSON.parse(response.body)['access_token']

# Transfer API connection
transfer_conn = Faraday.new(
  url: 'https://transfer.api.globusonline.org',
  headers: { 'Authorization': "Bearer #{token}" }
)

# List files at an endpoint
ls_ep = "/v0.10/operation/endpoint/#{ENDPOINT_ID}/ls"
ls_resp = transfer_conn.get(ls_ep)


# Create a directory https://docs.globus.org/api/transfer/file_operations/#make_directory
mkdir_ep = "/v0.10/operation/endpoint/#{ENDPOINT_ID}/mkdir"
mkdir_resp = transfer_conn.post(mkdir_ep) do |req|
  req.headers['Content-Type'] = 'application/json'
  req.body = {
    DATA_TYPE: 'mkdir',
    path: '/~/newdir'
  }.to_json
end

# Look up a user's identity ID in Globus https://docs.globus.org/api/auth/reference/#get_identities
user_email = 'lwrubel@stanford.edu'
id_ep = '/v2/api/identities'
id_resp = conn.get(id_ep) do |req|
  req.params['usernames'] = user_email
  req.headers['Authorization'] = "Bearer #{token}"
end

identities = JSON.parse(id_resp.body)['identities']
user_id = identities.select { |id| id['username'] == user_email }
id = user_id.first['id']

# Assign permissions to directory https://docs.globus.org/api/transfer/acl/#rest_access_create
perm_ep = "/v0.10/endpoint/#{ENDPOINT_ID}/access"
directory = '/~/newdir/' # must have trailing slash
perm_resp = transfer_conn.post(perm_ep) do |req|
  req.body = {
    DATA_TYPE: 'access',
    principal_type: 'identity',
    principal: id,
    path: directory,
    permissions: 'rw',
    notify_email: user_email
  }.to_json
  req.headers['Content-Type'] = 'application/json'
end

puts perm_resp.status
puts perm_resp.body

# Update access rule https://docs.globus.org/api/transfer/acl/#update_access_rule

# Delete a directory https://docs.globus.org/api/transfer/file_operations/#make_directory

