require 'net/http'

module Docker
  module Remote
    class BasicAuth
      attr_reader :creds

      def initialize(creds)
        @creds = creds
      end

      def make_get(path)
        Net::HTTP::Get.new(path).tap do |request|
          request.basic_auth(creds.username, creds.password)
        end
      end
    end
  end
end
