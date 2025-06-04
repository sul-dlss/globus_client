# frozen_string_literal: true

class GlobusClient
  # Handles unexpected responses when communicating with Globus
  class UnexpectedResponse
    # @param [Faraday::Response] response
    # https://docs.globus.org/api/transfer/file_operations/#common_errors
    # https://docs.globus.org/api/transfer/file_operations/#errors
    # https://docs.globus.org/api/transfer/acl/#common_errors
    # https://docs.globus.org/api/auth/reference/
    def self.call(response)
      case response.status
      when 400
        raise GlobusClient::BadRequestError, "Invalid path or another error with the request: #{response.body}"
      when 401
        raise GlobusClient::UnauthorizedError, "There was a problem with the access token: #{response.body} "
      when 403
        raise GlobusClient::ForbiddenError, "The operation requires privileges which the client does not have: #{response.body}"
      when 404
        raise GlobusClient::ResourceNotFound, "Endpoint ID not found or resource does not exist: #{response.body}"
      when 502
        raise GlobusClient::EndpointError, "Other error with endpoint: #{response.status} #{response.body}."
      when 503
        raise GlobusClient::ServiceUnavailable, 'The service is down for maintenance.'
      else
        raise GlobusClient::InternalServerError, "Unexpected response: #{response.status} #{response.body}."
      end
    end
  end
end
