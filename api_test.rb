# frozen_string_literal: true

require 'faraday'

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

# List files at an endpoint https://docs.globus.org/api/transfer/file_operations/#list_directory_contents
ls_endpoint = "/v0.10/operation/endpoint/#{ENDPOINT_ID}/ls"
ls_resp = transfer_conn.get(ls_endpoint)
puts ls_resp.body

# Create a directory https://docs.globus.org/api/transfer/file_operations/#make_directory
mkdir_endpoint = "/v0.10/operation/endpoint/#{ENDPOINT_ID}/mkdir"
mk_path = '/test3/' # must have trailing slash
mkdir_resp = transfer_conn.post(mkdir_endpoint) do |req|
  req.headers['Content-Type'] = 'application/json'
  req.body = {
    DATA_TYPE: 'mkdir',
    path: mk_path
  }.to_json
end
puts mkdir_resp.body

# Look up a user's identity ID in Globus https://docs.globus.org/api/auth/reference/#get_identities
user_email = 'lwrubel@stanford.edu'
id_endpoint = '/v2/api/identities'
id_resp = conn.get(id_endpoint) do |req|
  req.params['usernames'] = user_email
  req.headers['Authorization'] = "Bearer #{token}"
end

identities = JSON.parse(id_resp.body)['identities']
user_id = identities.select { |id| id['username'] == user_email }
id = user_id.first['id']

# Assign a user permissions for a directory https://docs.globus.org/api/transfer/acl/#rest_access_create
perm_endpoint = "/v0.10/endpoint/#{ENDPOINT_ID}/access"
directory = '/test3/' # must have trailing slash
perm_resp = transfer_conn.post(perm_endpoint) do |req|
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
puts perm_resp.body

# Update access rule 
# First must get ACL rule id https://docs.globus.org/api/transfer/acl/#rest_access_get_list
acl_endpoint = "/v0.10/endpoint/#{ENDPOINT_ID}/access_list"
acl_resp = transfer_conn.get(acl_endpoint) do |req|
  req.headers['Content-Type'] = 'application/json'
end
puts acl_resp.body

# Second find the ACL that has the identity id of the user and update ACL https://docs.globus.org/api/transfer/acl/#update_access_rule
acl_rules = JSON.parse(acl_resp.body)['DATA']
target_rules = acl_rules.select { |acl| acl['path'] == directory }
# to instead find rules by user identity id:
# target_rules = acl_rules.select { |acl| acl['principal'] == id }
rule_id = target_rules.first['id']

update_endpoint = "/v0.10/endpoint/#{ENDPOINT_ID}/access/#{rule_id}"
update_resp = transfer_conn.put(update_endpoint) do |req|
  req.body = {
    DATA_TYPE: 'access',
    permissions: 'r'
  }.to_json
  req.headers['Content-Type'] = 'application/json'
end
puts update_resp.status

# Delete data https://docs.globus.org/api/transfer/task_submit/#transfer_and_delete_documents
# "Transfer and delete are asynchronous operations, and result in a background task being created.
#  Both require a submission_id when submitted, and return a task_id on successful submission."

# First get a submission_id
submit_endpoint = '/v0.10/submission_id'
submit_resp = transfer_conn.get(submit_endpoint)
submission_id = JSON.parse(submit_resp.body)['value']

# Second submit a delete task with the submission_id
delete_endpoint = '/v0.10/delete'
delete_path = '/test3/'
delete_resp = transfer_conn.post(delete_endpoint) do |req|
  req.body = {
    DATA: [
      {
        DATA_TYPE: 'delete_item',
        path: delete_path
      }
    ],
    recursive: true,
    submission_id: submission_id,
    endpoint: ENDPOINT_ID
  }.to_json
  req.headers['Content-Type'] = 'application/json'
end
puts delete_resp.status
task_id = JSON.parse(delete_resp.body)['task_id']

# Third confirm the task completed successfully https://docs.globus.org/api/transfer/task/#get_task_by_id
# Can also get a task list at /task_list
task_endpoint = "/v0.10/task/#{task_id}"
task_resp = transfer_conn.get(task_endpoint)
puts task_resp.body

# Monitor task status
sleep(3)
task_resp = transfer_conn.get(task_endpoint)
# Will move from ACTIVE to SUCCEEDED
puts JSON.parse(task_resp.body)['status']
