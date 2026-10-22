# frozen_string_literal: true

class GlobusClient
  # Holds all of the client's custom exception classes
  module Errors
    # Base class for all of the client's custom exceptions, so that consumers can rescue any of them
    class Error < StandardError; end

    # Error raised when the Globus Auth or Transfer API returns a 400 error
    class BadRequestError < Error; end

    # Error raised by the Globus Auth API returns a 401 Unauthorized
    class UnauthorizedError < Error; end

    # Error raised when the Globus Auth or Transfer API returns a 403 Forbidden
    class ForbiddenError < Error; end

    # Error raised when the Globus Auth or Transfer API returns a 404 NotFound
    class ResourceNotFound < Error; end

    # Error raised when a consumer acts upon an access rule that was not found
    class AccessRuleNotFound < Error; end

    # Error raised when response has an unexpected error (e.g., an HTTP 500)
    class InternalServerError < Error; end

    # Error raised when the Globus Transfer API returns a 502 Bad Gateway
    class EndpointError < Error; end

    # Error raised when the remote server returns a 503 Bad Gateway
    class ServiceUnavailable < Error; end
  end
end
