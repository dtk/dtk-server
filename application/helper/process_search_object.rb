module Ramaze::Helper
  module ProcessSearchObject
    include XYZ
   private
    #fns that get _search_object
    def ret_search_object_in_request()

pp ret_request_params()

if model_name == :node

test = false
if test
  hash = {"id" => 2147483992}
else
hash = request_method_is_post?() ? ret_hash_search_object_in_post() : ret_hash_search_object_in_get()
end
else
      hash = request_method_is_post?() ? ret_hash_search_object_in_post() : ret_hash_search_object_in_get()
end
      hash ? SearchObject.create_from_input(hash,ret_session_context_id()) : nil
    end

 
   def ret_hash_search_object_in_get()
     #TODO: stub; incomplete
     columns = Model::FieldSet.default(model_name()).cols
     filter = ret_filter_when_get()
     hash_search_pattern = {
       :relation => model_name(),
       :columns => columns
     }
     hash_search_pattern.merge!(:filter => filter) if filter
     {"search_pattern" => hash_search_pattern}
   end

   def ret_filter_when_get()
     hash = ret_parsed_query_string_when_get() 
     field_set = Model::FieldSet.all_real(model_name())
     hash ? field_set.ret_where_clause_for_search_string(hash.reject{|k,v|k == :parent_id}) : nil
    end

    def ret_hash_search_object_in_post()
      (ret_request_params()||{})["search"]
    end

    ###
  end
end
