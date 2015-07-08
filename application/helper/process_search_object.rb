module Ramaze::Helper
  module ProcessSearchObject
    include XYZ

    private

    # fns that get _search_object
    def ret_search_object_in_request
      source = hash = nil
      if request_method_is_post?()
        hash = ret_hash_search_object_in_post()
      end
      if hash #request_method_is_post and it has search pattern
        source = :post_request
      elsif @action_set_params and not @action_set_params.empty?
        source = :action_set
        hash = ret_hash_search_object_in_action_set_params(@action_set_params)
      else
        source = :get_request
        hash = ret_hash_search_object_in_get()
      end
      SearchObject.create_from_input_hash(hash,source,ret_session_context_id()) if hash
   end


   def ret_hash_search_object_in_get
     # TODO: stub; incomplete
     filter = ret_filter_when_get()
     hash_search_pattern = {
       relation: model_name()
     }
     hash_search_pattern.merge!(filter: filter) if filter
     {"search_pattern" => hash_search_pattern}
   end

   def ret_filter_when_get
     hash = (ret_parsed_query_string_when_get()||{}).reject{|k,_v|k == :parent_id}
     return nil if hash.empty?
     [:and] + hash.map{|k,v|[:eq,k,v]}
    end

    def ret_hash_search_object_in_action_set_params(action_set_params)
      action_set_params["search"]
    end

    def ret_hash_search_object_in_post
      json_params = (ret_request_params()||{})["search"]
      if json_params and not json_params.empty?
        search_pattern = JSON.parse(json_params)
        if rest_request?()
          search_pattern["relation"] ||=  model_name()
        end
        {"search_pattern" => search_pattern}
      end
    end
  end
end
