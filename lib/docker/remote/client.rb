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

      def initialize(registry_url, repo, username = nil, password = nil)
        @registry_url = registry_url
        @repo = repo
        @username = username
        @password = password
      end

      def tags
        request = auth.make_get("/v2/#{repo}/tags/list")
        response = registry_http.request(request)
        potentially_raise_error!(response)
        JSON.parse(response.body)['tags']
      end

      def manifest_for(reference)
        request = auth.make_get("/v2/#{repo}/manifests/#{reference}")
        response = registry_http.request(request)
        potentially_raise_error!(response)
        JSON.parse(response.body)
      end

      def catalog
        request = auth.make_get("/v2/_catalog")
        response = registry_http.request(request)
        potentially_raise_error!(response)
        JSON.parse(response.body)
      end

      private

      def auth
        @auth ||= begin
          request = Net::HTTP::Get.new('/v2/')
          response = registry_http.request(request)

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

      def registry_uri
        @registry_uri ||= URI.parse(registry_url)
      end

      def registry_http
        @registry_http ||=
          Net::HTTP.new(registry_uri.host, registry_uri.port).tap do |http|
            http.use_ssl = true if registry_uri.scheme == 'https'
          end
      end
    end
  end
end
