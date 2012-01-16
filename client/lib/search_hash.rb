module R8
  module Client
    class SearchHash < Hash
      def cols=(cols)
        self[:columns] = cols
      end
      def filters=(filters)
        self[:filters] = filters
      end
      def post_body_hash()
        {:search => JSON.generate(self)}
      end
    end
  end
end
