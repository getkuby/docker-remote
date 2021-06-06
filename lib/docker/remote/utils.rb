require 'json'

module Docker
  module Remote
    module Utils
      def potentially_raise_error!(response)
        case response.code.to_i
          when 401
            raise UnauthorizedError, "401 Unauthorized: #{response.message}"
          when 404
            json = JSON.parse(response.body) rescue {}
            error = (json['errors'] || []).first || {}

            if error['code'] == 'NAME_UNKNOWN'
              raise UnknownRepoError, error['message']
            end

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
