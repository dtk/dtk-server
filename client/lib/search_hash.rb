module R8
  module Client
    class SearchHash < Hash
      def cols=(cols)
        self[:columns] = cols
      end
      def filter=(filter)
        self[:filter] = filter
      end
      def post_body_hash()
        {:search => JSON.generate(self)}
      end
    end
  end
end
