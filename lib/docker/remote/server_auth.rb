module Docker
  module Remote
    class ServerAuth
      attr_reader :auth_type, :params

      def initialize(auth_type, params)
        @auth_type = auth_type
        @params = params
      end

      def realm
        @params['realm']
      end

      def service
        @params['service']
      end
    end
  end
end
