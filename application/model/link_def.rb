require  File.expand_path('link_def/parse_serialized_form.rb', File.dirname(__FILE__))
module XYZ
  class LinkDef < Model
    extend LinkDefParseSerializedForm
    def self.create_needed_internal_links(node,component,node_link_defs_info)
      #get link_defs in node_link_defs_info that relate to internal links not linked already that connect to component
      #on either end. what is returned arelink defs annotated with their possible links
      relevant_link_defs = get_annotated_internal_link_defs(component,node_link_defs_info)
      return if relevant_link_defs.empty?
      #for each link def with multiple possibel link defs find the match; 
      #TODO: find good mechanism to get user input if there is a choice such as whether it is internal or external
      #look art passing in "stratagy" object which for example can indicate to make all "internal_external internal"
      strategy = {:internal_external_becomes_internal => true,:select_first => true}
      relevant_link_defs.each do |link_def|
        chosen_link = link_def.choose_internal_link(link_def[:possible_links],component,strategy)
        link_def[:chosen_link] = chosen_link if chosen_link #chosen link can be null if for example link has :type="internal_external" and external link is prefered"
      end

      #get all other components onnode that can be linked
      component.update_object!(:component_type, :extended_base, :implementation_id)
      component_id = component.id
      node_id = node.id
      sp_hash = {
        :model_name => :component,
        :filter => [:and, [:eq, :node_node_id, node_id],[:neq, :id, component_id]],
        :cols => [:component_type, :extended_base, :implementation_id, :node_node_id]
      }
      components = get_objs(component.model_handle,sp_hash) 
      components << component
      relevant_link_defs.each do |link_def|
        next unless link = link_def[:chosen_link]
        context = link.get_context(components)
        context #TODO: stub
      end

      #TODO: got here
=begin
      #TODO: more efficient would be to have clone object output have this info
      component.update_object!(:component_type,:extended_base,:implementation_id,:node_node_id)
      conn_profile = component.get_objects_col_from_sp_hash({:cols => [:connectivity_profile_internal]}).first
      return unless conn_profile
      #get all other components on node
      component_id = component.id
      sp_hash = {
        :model_name => :component,
        :filter => [:neq, :id, component_id],
        :cols => [:component_type,:most_specific_type, :extended_base, :implementation_id, :node_node_id]
      }
      other_cmps = get_children_from_sp_hash(:component,sp_hash)
      conn_info_list = conn_profile.match_other_components(other_cmps)
      return if conn_info_list.empty?
      parent_idh = component.id_handle.get_parent_id_handle

      conn_info_list.each do |conn_info|
        context = conn_info.get_context(component,conn_info[:other_component])
        (conn_info[:attribute_mappings]||[]).each do |attr_mapping|
          link = attr_mapping.ret_link(context)
          AttributeLink.create_attr_links(parent_idh,[link])
        end
      end
=end
    end

    def choose_internal_link(possible_links,component,strategy)
      #TODO: mostly stubbed fn
      #TODO: need to check if has contraint
      ret = nil
      return ret if possible_links.empty?
      raise Error.new("only select_first strataggy currently implemented") unless strategy[:select_first]
      ret = possible_links.first
      if ret[:type] == "internal_external"
        raise Error.new("only strategy internal_external_becomes_internal implemented") unless stratagy[:internal_external_becomes_internal]
      end
      component.update_object!(:component_type)
      ret.merge(:local_component_type => component[:component_type])
    end
  private

    def self.get_annotated_internal_link_defs(component,node_link_defs_info)
      ret = Array.new
      #shortcut; no links to create if less than two internal ports
      return ret if node_link_defs_info.size < 2

      #### get relevant link def possible links
      #find all link def ids that can be internal, local, and not connected already 
      component_id = component.id
      component_type = (component.update_object!(:component_type))[:component_type]
      relevant_link_def_ids = Array.new
      cmp_link_def_ids = Array.new # subset of above on this component
      ndx_relevant_link_defs = Hash.new #for splicing in possible_links TODO: see if more efficient to get possible_links
      #in intial call to get node_link_defs_info
      #these are the ones for which the possible links shoudl be found
      node_link_defs_info.each do |r|
        port = r[:port]
        link_def = r[:link_def]
        if %w{component_internal component_internal_external}.include?(port[:type]) and
            link_def[:local_or_remote] == "local" and
            not port[:connected]
          link_def_id = link_def[:id]
          relevant_link_def_ids << link_def_id
          ndx_relevant_link_defs[link_def_id] = link_def
          cmp_link_def_ids << link_def_id if link_def[:component_component_id] == component_id
        end
      end
      return ret if relevant_link_def_ids.empty?

      #get relevant possible_link link defs; these are ones that 
      #are children of relevant_link_def_ids and
      #internal_external have link_def_id in cmp_link_def_ids or remote_component_type == component_type
      sp_hash = {
        :cols => [:link_def_id, :remote_component_type,:position,:content,:type],
        :filter => [:and, [:oneof, :type, %w{internal internal_external}],
                          [:oneof, :link_def_id, relevant_link_def_ids],
                          [:or, [:eq,:remote_component_type,component_type],
                                [:oneof, :link_def_id,cmp_link_def_ids]]],
        :order_by => [{:field => :position, :ordet => "ASC"}]
      }
      poss_links = Model.get_objs(component.model_handle(:link_def_link),sp_hash)
      return ret if poss_links.empty?
      #splice in possible links
      poss_links.each do |poss_link|
        (ndx_relevant_link_defs[poss_link[:link_def_id]][:possible_links] ||= Array.new) << poss_link
      end
      
      #relevant link defs are ones that are in ndx_relevant_link_defs_info and have a possible link
      ret = ndx_relevant_link_defs.reject{|k,v|not v.has_key?(:possible_links)}.values
      ret
    end
  end
end

