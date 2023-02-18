# frozen_string_literal: true

class GlobusClient
  # Wraps API operations to request new access token if expired
  class TokenWrapper
    def self.refresh(config)
      yield
    rescue UnexpectedResponse::UnauthorizedError
      config.token = Authenticator.token(config.client_id, config.client_secret, config.auth_url)
      yield
    end
  end
end
