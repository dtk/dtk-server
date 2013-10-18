module XYZ
  class DependencyController < AuthController
    def rest__add_component_dependency()
      cmp_template = ret_component_template(:component_template_id)
      antecedent_cmp_template = ret_component_template(:other_component_id)
      rest_ok_response Dependency::Simple.create_component_dependency(cmp_template,antecedent_cmp_template)
    end
  end
end
