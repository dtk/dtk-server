module XYZ
  class Search_objectController < AuthController
    def save(explicit_hash=nil)
      hash_assignments = explicit_hash || request.params.dup
      redirect = (not (hash_assignments.delete("redirect").to_s == "false"))
      id = super(explicit_hash,:return_id => true)
      SearchObject.save_list_view_in_cache(id,hash_assignments,user_context())
      redirect "/xyz/#{model_name()}/display/#{id.to_s}" if redirect
    end
  end
end
