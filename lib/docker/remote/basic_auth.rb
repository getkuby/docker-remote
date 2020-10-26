require 'net/http'

module Docker
  module Remote
    class BasicAuth
      attr_reader :username, :password

      def initialize(username, password)
        @username = username
        @password = password
      end

      def make_get(path)
        Net::HTTP::Get.new(path).tap do |request|
          request.basic_auth(username, password)
        end
      end
    end
  end
end
