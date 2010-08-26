module XYZ
  class AttributeController < Controller
#TODO: move field set definition into meta/attribute/attribute.def.rb
    def self.field_set()
      [
        :id,
        :display_name,
        :external_attr_ref,
        :attribute_value,
        :description,
        :parent_id,
        :parent_path
      ]   
    end

    def component_display(parsed_query_string=nil)
      where_clause = parsed_query_string || ret_parsed_query_string()
      model_list = get_objects(@model_name.to_sym,field_set,where_clause)

      #TODO: should we be using default action name
      action_name = :list
      tpl = R8Tpl::TemplateR8.new("#{@model_name}/#{action_name}",user_context())
      tpl.assign("#{@model_name}_list",model_list)
      tpl.assign(:list_start_prev, 0)
      tpl.assign(:list_start_next, 0)

      return tpl.render(nil,false)
    end
  end
end
