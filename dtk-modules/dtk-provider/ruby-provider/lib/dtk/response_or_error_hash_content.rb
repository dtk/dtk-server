module DTKModule
  module DTK
    class ResponseOrErrorHashContent < ::Hash
      # status can be :ok, or :notok
      def initialize(status, hash_content)
        replace(status_hash(status).merge(hash_content))
      end

      module Key
        ERROR_CODE = :error_code
        ERROR_MESSAGE = :error_message
      end
      
      private
      
      def status_hash(status)
        case status
        when :ok then { success: 'true' }
        when :notok  then { success: 'false', error: 'true' }
        else fail "Unexpected status '#{status}'"
        end
      end

    end
  end
end

