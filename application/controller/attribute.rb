module XYZ
  class AttributeController < MainController
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
      #getting model_name by looking at self.class, (e.g., self.class can = XYZ::NodeController)
      model_name = Aux.demodulize(self.class.to_s).gsub(/Controller$/,"").downcase
      model_list = get_objects(model_name.to_sym,field_set,where_clause)

      action_name = :list #TODO: automatically determine this

      user_context = UserContext.new #TODO: stub
      tpl = R8Tpl::TemplateR8.new("#{model_name}/#{action_name}",user_context)
      tpl.assign("#{model_name}_list",model_list)
      tpl.assign(:list_start_prev, 0)
      tpl.assign(:list_start_next, 0)
      @ctrl_result[:tpl_contents] = tpl.render(nil,false) #nil, false args for testing
    end
  end
end
