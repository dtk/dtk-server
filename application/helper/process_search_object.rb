module Ramaze::Helper
  module ProcessSearchObject
    include XYZ
   private
    #fns that get _search_object
    def ret_search_object_in_request()

if model_name == :node
pp ret_request_params()
                  
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
  end
end
