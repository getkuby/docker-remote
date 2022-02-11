module Docker
  module Remote
    class Credentials
      attr_reader :username, :password

      def initialize(username, password)
        @username = username
        @password = password
      end
    end
  end
end
