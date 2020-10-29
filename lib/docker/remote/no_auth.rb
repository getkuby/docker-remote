module Docker
  module Remote
    class NoAuth
      include Singleton

      def make_get(path)
        Net::HTTP::Get.new(path)
      end
    end
  end
end
