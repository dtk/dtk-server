module DTK
  module V1
    class ServiceController < AuthController

      def rest__get
        # DEBUG SNIPPET >>> REMOVE <<<
        require 'ap'
        ap "WORKINGGGG!!!!"
        rest_ok_response
      end

    end
  end
end