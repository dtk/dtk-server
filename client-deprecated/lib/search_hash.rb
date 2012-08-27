module DTK
  module Client
    class SearchHash < Hash
      def cols=(cols)
        self.merge!(:columns => cols)
      end
      def filter=(filter)
        self.merge!(:filter => filter)
      end
      def set_order_by!(col,dir="ASC")
        unless %w{ASC DESC}.include?(dir)
          raise Error.new("set order by direction must by 'ASC' or 'DESC'")
        end
        order_by = 
          [{
          :field => col,
          :order => dir
        }]
        self.merge!(:order_by => order_by)
      end

      def post_body_hash()
        {:search => JSON.generate(self)}
      end
    end
  end
end
