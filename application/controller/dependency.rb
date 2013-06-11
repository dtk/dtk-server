module XYZ
  class DependencyController < AuthController
    def rest__add_component_dependency()
      cmp_id,type,other_component_id = ret_non_null_request_params(:component_id,:type,:other_component_id)
      hash_info = {
        :other_component_id => other_component_id,
      }
      rest_ok_response Dependency.add_component_dependency(id_handle(cmp_id,:component),type,hash_info)
    end
  end
end
