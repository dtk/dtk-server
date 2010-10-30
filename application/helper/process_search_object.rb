module Ramaze::Helper
  module ProcessSearchObject
    include XYZ
   private
    #fns that get _search_object
    def ret_search_object_in_request()
  pp ret_request_params()
      source = hash = nil
      if @action_set_params and not @action_set_params.empty?
        source = :action_set
        hash = ret_hash_search_object_in_action_set_params(@action_set_params)
      elsif request_method_is_post?() 
        source = :post_request
        hash = ret_hash_search_object_in_post() 
      else 
        source = :get_request
        hash = ret_hash_search_object_in_get()
      end
      hash ? SearchObject.create_from_input_hash(hash,source,ret_session_context_id()) : nil
   end

 
   def ret_hash_search_object_in_get()
     #TODO: stub; incomplete
     filter = ret_filter_when_get()
     hash_search_pattern = {
       :relation => model_name()
     }
     hash_search_pattern.merge!(:filter => filter) if filter
     {"search_pattern" => hash_search_pattern}
   end

   def ret_filter_when_get()
     hash = (ret_parsed_query_string_when_get()||{}).reject{|k,v|k == :parent_id}
     return nil if hash.empty?
     [:and] + hash.map{|k,v|[:eq,k,v]}
    end

    def ret_hash_search_object_in_action_set_params(action_set_params)
      action_set_params["search"]
    end

    def ret_hash_search_object_in_post()
      json = (ret_request_params()||{})["search"]
      json ? JSON.parse(json) : nil
    end

    ###
  end
end
