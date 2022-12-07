# frozen_string_literal: true

class GlobusClient
  # Handles unexpected responses when communicating with Globus
  class UnexpectedResponse
    # Error raised when the Globus Auth or Transfer API returns a 400 error
    class BadRequestError < StandardError; end

    # Error raised by the Globus Auth API returns a 401 Unauthorized
    class UnauthorizedError < StandardError; end

    # Error raised when the Globus Auth or Transfer API returns a 403 Forbidden
    class ForbiddenError < StandardError; end

    # Error raised when the Globus Auth or Transfer API returns a 404 NotFound
    class ResourceNotFound < StandardError; end

    # Error raised when the Globus Transfer API returns a 502 Bad Gateway
    class EndpointError < StandardError; end

    # Error raised when the remote server returns a 503 Bad Gateway
    class ServiceUnavailable < StandardError; end

    # @param [Faraday::Response] response
    # https://docs.globus.org/api/transfer/file_operations/#common_errors
    # https://docs.globus.org/api/transfer/file_operations/#errors
    # https://docs.globus.org/api/transfer/acl/#common_errors
    # https://docs.globus.org/api/auth/reference/
    def self.call(response)
      case response.status
      when 400
        raise BadRequestError, "Invalid path or another error with the request: #{response.body}"
      when 401
        raise UnauthorizedError, "There was a problem with the access token: #{response.body} "
      when 403
        raise ForbiddenError, "The operation requires privileges which the client does not have: #{response.body}"
      when 404
        raise ResourceNotFound, "Endpoint ID not found or resource does not exist: #{response.body}"
      when 502
        raise EndpointError, "Other error with endpoint: #{response.body}"
      when 503
        raise ServiceUnavailable, "The service is down for maintenance."
      else
        raise StandardError, "Unexpected response: #{response.status} #{response.body}"
      end
    end
  end
end
