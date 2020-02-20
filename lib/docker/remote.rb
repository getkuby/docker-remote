require 'net/http'
require 'uri'

module Docker
  module Remote
    autoload :Client,     'docker/remote/client'
    autoload :ServerAuth, 'docker/remote/server_auth'
  end
end
