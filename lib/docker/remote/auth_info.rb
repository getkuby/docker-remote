module Docker
  module Remote
    class AuthInfo
      class << self
        def from_header(header, creds)
          idx = header.index(' ')
          auth_type = header[0..idx].strip.downcase

          params = header[idx..-1].split(',').each_with_object({}) do |param, ret|
            key, value = param.split('=')
            ret[key.strip] = value.strip[1..-2]  # remove quotes
          end

          new(auth_type, params, creds)
        end
      end


      attr_reader :auth_type, :params, :creds

      def initialize(auth_type, params, creds)
        @auth_type = auth_type
        @params = params
        @creds = creds
      end

      def strategy
        @strategy ||= case auth_type
          when 'bearer'
            BearerAuth.new(self, creds)
          when 'basic'
            BasicAuth.new(creds)
          else
            raise UnsupportedAuthTypeError,
              "unsupported Docker auth type '#{auth_type}'"
        end
      end
    end
  end
end
