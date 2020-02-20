require 'json'

module Docker
  module Remote
    class ClientError < StandardError; end
    class ServerError < StandardError; end
    class UnauthorizedError < ClientError; end
    class NotFoundError < ClientError; end

    class Client
      attr_reader :registry_url, :repo, :username, :password

      def initialize(registry_url, repo, username = nil, password = nil)
        @registry_url = registry_url
        @repo = repo
        @username = username
        @password = password
      end

      def tags
        request = make_get("/v2/#{repo}/tags/list")
        response = registry_http.request(request)
        potentially_raise_error!(response)
        JSON.parse(response.body)['tags']
      end

      def manifest_for(reference)
        request = make_get("/v2/#{repo}/manifests/#{reference}")
        response = registry_http.request(request)
        potentially_raise_error!(response)
        JSON.parse(response.body)
      end

      def catalog
        request = make_get("/v2/_catalog")
        response = registry_http.request(request)
        potentially_raise_error!(response)
        JSON.parse(response.body)
      end

      private

      def token
        @token ||= begin
          uri = URI.parse(server_auth.realm)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true if uri.scheme == 'https'

          request = Net::HTTP::Get.new(
            "#{uri.request_uri}?service=#{server_auth.service}&scope=repository:#{repo}:pull"
          )

          if username && password
            request.basic_auth(username, password)
          end

          response = http.request(request)
          potentially_raise_error!(response)
          JSON.parse(response.body)['token']
        end
      end

      def server_auth
        @server_auth ||= begin
          request = Net::HTTP::Get.new('/v2/')
          response = registry_http.request(request)
          auth = response['www-authenticate']

          idx = auth.index(' ')
          auth_type = auth[0..idx].strip

          params = auth[idx..-1].split(',').each_with_object({}) do |param, ret|
            key, value = param.split('=')
            ret[key.strip] = value.strip[1..-2]  # remove quotes
          end

          ServerAuth.new(auth_type, params)
        end
      end

      def registry_uri
        @registry_uri ||= URI.parse(registry_url)
      end

      def registry_http
        @registry_http ||= Net::HTTP.new(registry_uri.host, registry_uri.port).tap do |http|
          http.use_ssl = true if registry_uri.scheme == 'https'
        end
      end

      def make_get(path)
        Net::HTTP::Get.new(path).tap do |request|
          request['Authorization'] = "Bearer #{token}"
        end
      end

      def potentially_raise_error!(response)
        case response.code.to_i
          when 401
            raise UnauthorizedError, "401 Unauthorized: #{response.message}"
          when 404
            raise NotFoundError, "404 Not Found: #{response.message}"
        end

        case response.code.to_i / 100
          when 4
            raise ClientError, "#{response.code}: #{response.message}"
          when 5
            raise ServerError, "#{response.code}: #{response.message}"
        end
      end
    end
  end
end
