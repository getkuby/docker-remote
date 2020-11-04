require 'json'
require 'net/http'
require 'uri'

module Docker
  module Remote
    class DockerRemoteError < StandardError; end
    class UnsupportedVersionError < DockerRemoteError; end
    class UnexpectedResponseCodeError < DockerRemoteError; end

    class Client
      include Utils

      attr_reader :registry_url, :repo, :username, :password

      PORTMAP = { 'ghcr.io' => 443 }.freeze
      DEFAULT_PORT = 443
      STANDARD_PORTS = [DEFAULT_PORT, 80].freeze

      def initialize(registry_url, repo, username = nil, password = nil)
        @registry_url = registry_url
        @repo = repo
        @username = username
        @password = password
      end

      def tags
        response = get("/v2/#{repo}/tags/list")
        potentially_raise_error!(response)
        JSON.parse(response.body)['tags']
      end

      def manifest_for(reference)
        response = get("/v2/#{repo}/manifests/#{reference}")
        potentially_raise_error!(response)
        JSON.parse(response.body)
      end

      def catalog
        response = get("/v2/_catalog")
        potentially_raise_error!(response)
        JSON.parse(response.body)
      end

      private

      def auth
        @auth ||= begin
          response = get('/v2/', use_auth: nil)

          case response.code
            when '200'
              NoAuth.instance
            when '401'
              www_auth(response)
            when '404'
              raise UnsupportedVersionError,
                "the registry at #{registry_url} doesn't support v2 "\
                  'of the Docker registry API'
            else
              raise UnexpectedResponseCodeError,
                "the registry at #{registry_url} responded with an "\
                  "unexpected HTTP status code of #{response.code}"
          end
        end
      end

      def www_auth(response)
        auth = response['www-authenticate']

        idx = auth.index(' ')
        auth_type = auth[0..idx].strip

        params = auth[idx..-1].split(',').each_with_object({}) do |param, ret|
          key, value = param.split('=')
          ret[key.strip] = value.strip[1..-2]  # remove quotes
        end

        case auth_type.downcase
          when 'bearer'
            BearerAuth.new(params, repo, username, password)
          when 'basic'
            BasicAuth.new(username, password)
          else
            raise UnsupportedAuthTypeError,
              "unsupported Docker auth type '#{auth_type}'"
        end
      end

      def get(path, http: registry_http, use_auth: auth, limit: 5)
        if limit == 0
          raise DockerRemoteError, 'too many redirects'
        end

        request = if use_auth
          use_auth.make_get(path)
        else
          Net::HTTP::Get.new(path)
        end

        response = http.request(request)

        case response
          when Net::HTTPRedirection
            redirect_uri = URI.parse(response['location'])
            redirect_http = make_http(redirect_uri)
            return get(
              redirect_uri.path, {
                http: redirect_http,
                use_auth: use_auth,
                limit: limit - 1
              }
            )
        end

        response
      end

      def registry_uri
        @registry_uri ||= begin
          host_port, *rest = registry_url.split('/')
          host, port = host_port.split(':')

          ports = if port
            [port.to_i]
          elsif prt = PORTMAP[host]
            [prt]
          else
            STANDARD_PORTS
          end

          port = ports.find { |port| can_connect?(host, port) }

          unless port
            raise DockerRemoteError, "couldn't determine what port to connect to"
          end

          scheme = port == DEFAULT_PORT ? 'https' : 'http'
          URI.parse("#{scheme}://#{host}:#{port}/#{rest.join('/')}")
        end
      end

      def make_http(uri)
        Net::HTTP.new(uri.host, uri.port).tap do |http|
          http.use_ssl = true if uri.scheme == 'https'
        end
      end

      def registry_http
        @registry_http ||= make_http(registry_uri)
      end

      # Adapted from: https://spin.atomicobject.com/2013/09/30/socket-connection-timeout-ruby/
      def can_connect?(host, port)
        # Convert the passed host into structures the non-blocking calls
        # can deal with
        addr = Socket.getaddrinfo(host, nil)
        sockaddr = Socket.pack_sockaddr_in(port, addr[0][3])
        timeout = 3

        Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0).tap do |socket|
          socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

          begin
            # Initiate the socket connection in the background. If it doesn't fail
            # immediately it will raise an IO::WaitWritable (Errno::EINPROGRESS)
            # indicating the connection is in progress.
            socket.connect_nonblock(sockaddr)

          rescue IO::WaitWritable
            # IO.select will block until the socket is writable or the timeout
            # is exceeded - whichever comes first.
            if IO.select(nil, [socket], nil, timeout)
              begin
                # Verify there is now a good connection
                socket.connect_nonblock(sockaddr)
              rescue Errno::EISCONN
                # Good news everybody, the socket is connected!
                socket.close
                return true
              rescue
                # An unexpected exception was raised - the connection is no good.
                socket.close
              end
            else
              # IO.select returns nil when the socket is not ready before timeout
              # seconds have elapsed
              socket.close
            end
          end
        end

        false
      end
    end
  end
end
