module Ramaze::Helper
  module ProcessSearchObject
    include XYZ
   private
    #fns that get _search_object
    def ret_search_object_in_request()
      hash = request_method_is_post?() ? ret_hash_search_object_in_post() : ret_hash_search_object_in_get()
      hash ? SearchObject.new(hash) : nil
    end

    def ret_hash_search_object_in_get()
      raise ErrorNotImplemented.new("search object when operation is 'get'")
    end

    def ret_hash_search_object_in_post()
      (ret_request_params()||{})["search"]
    end

    ###
    class SearchObject 
      def initialize(hash)
        @id = hash["id"]
        @name = hash["name"]
        @search_pattern = hash["search_pattern"] ? SearchString.new(hash["search_pattern"]) : nil
        @save = hash["save"]
        raise Error.new("search object is ill-formed") unless is_valid?
      end
      
      def save?()
        save  
      end
      def needs_to_be_retrieved?()
        (id and not search_pattern) ? true : nil
      end

      def update!(saved_search_obj)
        @search_pattern = saved_search_obj["search_pattern"]
        @name = saved_search_obj["display_name"]
      end

      attr_reader :id, :name, :search_pattern, :save
     private
      def is_valid?()
        #TODO: can do finer grain validation
        (id or search_pattern) ? true : nil
      end

      class SearchString
        def initialize(hash)
          @columns = hash[key_in_search_pattern(:columns)]
          @relation = hash[key_in_search_pattern(:relation)]
          @filter = hash[key_in_search_pattern(:filter)]
          @order_by = hash[key_in_search_pattern(:order_by)]
          @paging = hash[key_in_search_pattern(:paging)]
        end
       private
        attr_reader :columns, :relation, :filter, :order_by, :paging
        def key_in_search_pattern(symbol)
          ":#{symbol}"
        end
      end
    end
  end
end
