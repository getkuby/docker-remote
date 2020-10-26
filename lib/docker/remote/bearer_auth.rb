require 'json'
require 'net/http'
require 'uri'

module Docker
  module Remote
    class BearerAuth
      include Utils

      attr_reader :params, :repo, :username, :password

      def initialize(params, repo, username, password)
        @params = params
        @repo = repo
        @username = username
        @password = password
      end

      def make_get(path)
        Net::HTTP::Get.new(path).tap do |request|
          request['Authorization'] = "Bearer #{token}"
        end
      end

      private

      def realm
        @realm ||= URI.parse(params['realm'])
      end

      def service
        @serivce ||= params['service']
      end

      def token
        @token ||= begin
          http = Net::HTTP.new(realm.host, realm.port)
          http.use_ssl = true if realm.scheme == 'https'

          request = Net::HTTP::Get.new(
            "#{realm.request_uri}?service=#{service}&scope=repository:#{repo}:pull"
          )

          if username && password
            request.basic_auth(username, password)
          end

          response = http.request(request)
          potentially_raise_error!(response)
          JSON.parse(response.body)['token']
        end
      end
    end
  end
end
