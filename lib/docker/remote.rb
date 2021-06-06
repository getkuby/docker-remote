module Docker
  module Remote
    class ClientError < StandardError; end
    class ServerError < StandardError; end
    class UnauthorizedError < ClientError; end
    class NotFoundError < ClientError; end
    class UnknownRepoError < ClientError; end

    class UnsupportedAuthTypeError < StandardError; end

    autoload :BasicAuth,  'docker/remote/basic_auth'
    autoload :BearerAuth, 'docker/remote/bearer_auth'
    autoload :Client,     'docker/remote/client'
    autoload :NoAuth,     'docker/remote/no_auth'
    autoload :Utils,      'docker/remote/utils'
  end
end
