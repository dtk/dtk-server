
module XYZ
  class Attribute_linkController < Controller
    def list_legal_connections(project_name,parsed_query_string=nil) #stub for parent_id/model_name
      opts = {:depth => :deep}
      parent_id = nil
      #TODO stub to get project id from project name
      parent_uri = "/project/#{project_name}"

      c = ret_session_context_id()
      Model.create_simple_instance?(parent_uri,c)
      parent_id = ret_id_from_uri(parent_uri)
      ###end of stub
      where_clause = {:parent_id => parent_id}

      component_ds = Model.get_objects_just_sequel_dataset(:component,c,where_clause,{:field_set => [:id,:external_cmp_ref]}).from_self(:alias => :component)
      attribute_ds = Model.get_objects_just_sequel_dataset(:attribute,c,nil,{:field_set => [:id,:external_attr_ref,:component_component_id]}).from_self(:alias => :attribute)

      attribute_link_ds = Model.get_objects_just_sequel_dataset(:attribute_link,c)
#     pp component_ds.from_self.join_table(:inner,attribute_ds,{:component_component_id => :id}).all
#      ds= component_ds.graph(attribute_ds,{:component_component_id => :id},{:join_type => :inner}).graph(:attribute__link,{:input_id => :id})
      ds= component_ds.graph(attribute_ds,{:component_component_id => :id},{:join_type => :inner,:table_alias => :attribute}).graph(attribute_link_ds,{:input_id => :id},{:table_alias => :attribute_link}).where({:attribute_link__id => nil})

      puts ds.sql
      pp ds.all
=begin
look at wrapping in XYZ::SQL calls that take an ordered list where each element is
one that takes <relation_type>,where,field_set

the other that wraps graph and then applies both "sides" of results through 
          hash = process_raw_scalar_hash!(raw_hash,db_rel,c)
what about?
	  db_rel[:model_class].new(hash,c,relation_type)
=end

      model_list = get_objects(:component,where_clause,opts)

      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{default_action_name()}",user_context())
      tpl.assign("#{model_name().to_s}_list",model_list)
      #TODO: needed to below back in so template did not barf
      tpl.assign(:list_start_prev, 0)
      tpl.assign(:list_start_next, 0)
 # }
      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      return {:content => tpl.render()}
    end
  end
end
