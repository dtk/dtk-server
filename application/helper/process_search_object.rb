module Ramaze::Helper
  module ProcessSearchObject
    include XYZ
   private
    #fns that get _search_object
    def ret_search_object_in_request()

if model_name == :node
      hash = {"id" => 2147483992}
else
hash = request_method_is_post?() ? ret_hash_search_object_in_post() : ret_hash_search_object_in_get()
end

#      hash = request_method_is_post?() ? ret_hash_search_object_in_post() : ret_hash_search_object_in_get()
      hash ? SearchObject.create_from_input(hash,ret_session_context_id()) : nil
    end

    def ret_hash_search_object_in_get()
      raise ErrorNotImplemented.new("search object when operation is 'get'")
    end

    def ret_hash_search_object_in_post()
      (ret_request_params()||{})["search"]
    end

    ###
=begin

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
=end
  end
end
