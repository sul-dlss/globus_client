# frozen_string_literal: true

module Globus
  class Client
    # Handles unexpected responses when communicating with Globus
    class UnexpectedResponse
      # Error raised when the remote server returns a 400 BadRequest
      class BadRequestError < StandardError; end

      # Error raised when the remote server returns a 401 Unauthorized
      class UnauthorizedError < StandardError; end

      # Error raised when the remote server returns a 403 Forbidden
      class ForbiddenError < StandardError; end

      # Error raised when the remote server returns a 404 NotFound
      class ResourceNotFound < StandardError; end

      # Error raised when the remote server returns a 409 Conflict
      class ConflictError < StandardError; end

      # Error raised when the remote server returns a 503 Bad Gateway
      class EndpointError < StandardError; end

      # Error raised when the remote server returns a 503 Bad Gateway
      class ServerError < StandardError; end

      # @param [Faraday::Response] response
      # See https://docs.globus.org/api/search/errors/
      def self.call(response)
        case response.status
        when 400
          raise BadRequestError, "There was an error with your request: #{response.body}"
        when 401
          raise UnauthorizedError, "There was an error with authentication or the access token."
        when 403
          raise ForbiddenError, "The operation requires privileges which the client does not have."
        when 404
          raise ResourceNotFound, "Resource does not exist or is missing."
        when 409
          raise ConflictError,
            "Request is blocked, disallowed, or not consistent with the state of the service,
                 e.g. trying to cancel a task which has already completed?"
        when 502
          raise EndpointError, "Other error with endpoint."
        when 503
          raise ServerError, "The Globus Search backend was too slow trying to serve the request,"
        else
          raise "Unexpected response: #{response.status} #{response.body}"
        end
      end
    end
  end
end
