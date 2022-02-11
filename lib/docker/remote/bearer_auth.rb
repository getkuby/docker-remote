require 'json'
require 'net/http'
require 'uri'

module Docker
  module Remote
    class BearerAuth
      include Utils

      attr_reader :auth_info, :creds

      def initialize(auth_info, creds)
        @auth_info = auth_info
        @creds = creds
      end

      def make_get(path)
        Net::HTTP::Get.new(path).tap do |request|
          request['Authorization'] = "Bearer #{token}"
        end
      end

      private

      def realm
        @realm ||= URI.parse(auth_info.params['realm'])
      end

      def service
        @serivce ||= auth_info.params['service']
      end

      def token
        @token ||= begin
          http = Net::HTTP.new(realm.host, realm.port)
          http.use_ssl = true if realm.scheme == 'https'

          url_params = { service: service }

          if scope = auth_info.params['scope']
            url_params[:scope] = scope
          end

          request = Net::HTTP::Get.new(
            "#{realm.request_uri}?#{URI.encode_www_form(url_params)}"
          )

          if creds.username && creds.password
            request.basic_auth(creds.username, creds.password)
          end

          response = http.request(request)
          potentially_raise_error!(response)
          body_json = JSON.parse(response.body)
          body_json['token'] || body_json['access_token']
        end
      end
    end
  end
end
