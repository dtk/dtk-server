module XYZ
  #module MixinFrontendIntegrationStub not clear why mixin not working so explictly have class def
  class MainController < Controller
    def intg__component__list()
      error_405 unless request.get?
      http_opts = ret_parsed_query_string()
      c = ret_session_context_id()
      where_clause = http_opts[:display_name] ?
	"display_name ~ '^#{http_opts[:display_name]}'" : nil
     #TBD: generate list of queries and apply [fn that removes nil] then .join(" and ")
      objs = Object.get_objects(:component,c,where_clause)      
      objs.map{|o|o.object_slice([:display_name,:description,:id])}
    end

    def intg__component(guid)
      error_405 unless request.get?
      c = ret_session_context_id()
      obj = Object.get_object(IDHandle[:c => c,:guid => guid])
      obj.object_slice([:display_name,:description,:id,:external_cmp_ref])
    end

    def intg__component_attribute_list(component_guid)
      error_405 unless request.get?
      c = ret_session_context_id()
      cmp_guid = IDHandle[:c => c,:guid => component_guid]
      objs = Object.get_objects_wrt_parent(:attribute,cmp_guid)
      objs.map{|o|o.object_slice([:display_name,:description,:id,:data_type,:port_type])}
    end
    def intg__project_add_component(target_project_guid)
      error_405 unless request.get?
      c = ret_session_context_id()
      http_opts = ret_parsed_query_string()
      source_cmp_guid =  http_opts[:component]
      new_uris = Object.clone(IDHandle[:c => c,:guid => source_cmp_guid],IDHandle[:c => c, :guid => target_project_guid], :component)
     redirect route('list/' + new_uris[0] + '.json') unless new_uris.nil? or new_uris.empty?
    end

    def intg__attribute_link_list(attr_guid)
      error_405 unless request.get?
      c = ret_session_context_id()
      where_clause = "input_id = #{attr_guid} OR output_id = #{attr_guid}"
      Object.get_objects(:attribute_link,c,where_clause)
    end

    def intg__attribute(guid)
      error_405 unless request.get?
      c = ret_session_context_id()
      obj = Object.get_object(IDHandle[:c => c,:guid => guid])
      obj.object_slice([:display_name,:description,:id,:propagation_type,:constraints,:attribute_value,:data_type,:external_attr_ref,:executable?,:hidden?,:port_type])
    end
    def intg__create_link(i_attr_guid)
      error_405 unless request.get?
      c = ret_session_context_id()
      http_opts = ret_parsed_query_string()
      proj_id_handle = IDHandle[:c => c, :guid => http_opts[:project_id]]
      o_attr_id_handle = IDHandle[:c => c, :guid =>http_opts[:output_id]]
      i_attr_id_handle = IDHandle[:c => c, :guid => i_attr_guid]
      new_uris = AttributeLink.create(proj_id_handle,i_attr_id_handle,o_attr_id_handle,"")
      redirect route('list/' + new_uris[0] + '.json') unless new_uris.nil? or new_uris.empty?
    end
  end
end


Ramaze::Route[ 'intg create_link' ] = lambda do |path, request|
  "/intg/create_link/" +$1 + ".json" if path =~ %r{^/intg/attribute/([0-9]+)/create_link$}
end

Ramaze::Route[ 'intg attribute' ] = lambda do |path, request|
  "/intg/attribute/" +$1 + ".json" if path =~ %r{^/intg/attribute/([0-9]+)$}
end

Ramaze::Route[ 'intg attribute_link_list' ] = lambda do |path, request|
  "/intg/attribute_link_list/" +$1 + ".json" if path =~ %r{^/intg/attribute/([0-9]+)/link/list$}
end

Ramaze::Route[ 'intg project_add_component' ] = lambda do |path, request|
  "/intg/project_add_component/" +$1 + ".json" if path =~ %r{^/intg/project/([0-9]+)/add_component$}
end

Ramaze::Route[ 'intg component_attribute_list' ] = lambda do |path, request|
  "/intg/component_attribute_list/" +$1 + ".json" if path =~ %r{^/intg/component/([0-9]+)/attribute/list$}
end

Ramaze::Route[ 'intg' ] = lambda do |path, request|
  $1 + ".json" if path =~ %r{(^/intg/.+$)}
end




