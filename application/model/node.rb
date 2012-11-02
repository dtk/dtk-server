r8_nested_require('node','clone')
r8_nested_require('node','meta')
module XYZ
  class Node < Model
    r8_nested_require('node','template')
    include NodeClone
    
    set_relation_name(:node,:node)
    extend NodeMetaClassMixin 

    def self.common_columns()
      [
       :id,
       :group_id,
       :display_name,
       :name,
       :os_type,
       :type,
       :description,
       :status,
       :target_id,
       :ui,
       :external_ref
      ]
    end

    ### virtual column defs
    #######################
    #TODO: write as sql fn for efficiency
    def has_pending_change()
      ((self[:action]||{})[:count]||0) > 0
    end

    def status()
      (not self[:is_deployed]) ? "staged" : self[:operational_status]
    end

    def target_id()
      self[:datacenter_datacenter_id]
    end

    def name()
      self[:display_name]
    end

    #######################
    ######### Model apis

    def self.list(model_handle,opts={})
      target_filter = (opts[:target_idh] ? [:eq,:datacenter_datacenter_id,opts[:target_idh].get_id()] : [:neq,:datacenter_datacenter_id,nil])
      filter = [:and, [:oneof, :type, ["instance","staged"]], target_filter]
      sp_hash = {
        :cols => common_columns(),
        :filter => filter
      }
      get_objs(model_handle,sp_hash)
    end

    def info_about(about)
      case about
       when :components
        get_objs(:cols => [:components]).map do |r|
          cmp = r[:component]
          cmp.hash_subset(:id,:dsecription).merge(:display_name => cmp.display_name_print_form())
        end.sort{|a,b|a[:display_name] <=> b[:display_name]}
       else
        raise Error.new("TODO: not implemented yet: processing of info_about(#{about})")        
      end
    end

    def self.check_valid_id(model_handle,id)
      filter = 
        [:and,
         [:eq, :id, id],
         [:oneof, :type, ["instance","staged"]],
         [:neq, :datacenter_datacenter_id, nil]]
      check_valid_id_helper(model_handle,id,filter)
    end

    def self.name_to_id(model_handle,name)
      sp_hash =  {
        :cols => [:id],
           :filter => [:and,
                       [:eq, :display_name, name],
                       [:oneof, :type, ["instance","staged"]],
                       [:neq, :datacenter_datacenter_id, nil]]
      }
      name_to_id_helper(model_handle,name,sp_hash)
    end

    def get_and_update_status!()
      #shortcut
      if has_key?(:is_deployed)
        return  "staged" if not self[:is_deployed]
      end
      update_object!(:is_deployed,:external_ref,:operational_status)
      return  "staged" if not self[:is_deployed]
      get_and_update_operational_status!()
    end

    def get_and_update_operational_status!()
      update_object!(:external_ref,:operational_status)
      op_status = CommandAndControl.get_node_operational_status(self)
      if op_status
        unless self[:operational_status] == op_status
          update_operational_status!(op_status)
        end
      end
      op_status || self[:operational_status]
    end

    def is_node_group?()
      ["node_group_instance"].include?(self[:type])
    end

    #attribute on node
    def update_operational_status!(op_status)
      update(:operational_status => op_status.to_s)
      self[:operational_status] = op_status.to_s
    end

    def self.pbuilderid(node)
      node.update_object!(:external_ref)
      (node[:external_ref]||{})[:instance_id]
    end
    def pbuilderid()
      Node.pbuilderid(self)
    end
    
    def get_virtual_attribute(attribute_name,cols,field_to_match=:display_name)
      sp_hash = {
        :model_name => :attribute,
        :filter => [:eq, field_to_match, attribute_name],
        :cols => cols
      }
      get_children_from_sp_hash(:attribute,sp_hash).first
    end
    #TODO: may write above in terms of below
    def get_virtual_attributes(attribute_names,cols,field_to_match=:display_name)
      sp_hash = {
        :model_name => :attribute,
        :filter => [:oneof, field_to_match, attribute_names],
        :cols => Aux.array_add?(cols,field_to_match)
      }
      get_children_from_sp_hash(:attribute,sp_hash)
    end

    def self.get_virtual_attributes(attrs_to_get,cols,field_to_match=:display_name)
      ret = Hash.new
      #TODO: may be able to avoid this loop
      attrs_to_get.each do |node_id,hash_value|
        attr_info = hash_value[:attribute_info]
        node = hash_value[:node]
        attr_names = attr_info.map{|a|a[:attribute_name].to_s}
        rows = node.get_virtual_attributes(attr_names,cols,field_to_match)
        rows.each do |attr|
          attr_name = attr[field_to_match]
          ret[node_id] ||= Hash.new
          ret[node_id][attr_name] = attr
        end
      end
      ret
    end

    #### related to distinguishing bewteen nodes and node groups

    def self.get_node_or_ng_summary(node_mh,node_ids)
      ret = Hash.new
      return ret if node_ids.empty?
      sp_hash = {
        :cols => [:id,:type,:node_or_ng_summary],
        :filter => [:oneof, :id, node_ids]
      }
      get_objs(node_mh,sp_hash).inject({}) do |ret,n|
        n.delete(:node_group_relation)
        node_member = n.delete(:node_member)
        node_id = n[:id]
        if n.is_node_group?()
          pntr = ret[node_id] ||= NodeGroup.create_as(n).merge(:node_group_members => Array.new)
          pntr[:node_group_members] << node_member if node_member
          ret
        else
          ret.merge(node_id => n)
        end
      end
    end

    def is_node?()
      update_object!(:type)
       NodeTypes.include?(self[:type])
    end
    def is_node_group?()
      #short circuit
      return true if kind_of?(NodeGroup)
      update_object!(:type)
      NodeGroupTypes.include?(self[:type])
    end
    NodeTypes = %w{instance image staged}
    NodeGroupTypes = %w{node_group_instance}

    #### end: related to distinguishing bewteen nodes and node groups


    #attribute on component on node
    #assumption is that component cannot appear more than once on node
    def get_virtual_component_attribute(cmp_assign,attr_assign,cols)
      base_sp_hash = {
        :model_name => :component,
        :filter => [:and, [:eq, cmp_assign.keys.first,cmp_assign.values.first],[:eq, :node_node_id,self[:id]]],
        :cols => [:id]
        }
      join_array = 
        [{
           :model_name => :attribute,
           :convert => true,
           :join_type => :inner,
           :filter => [:eq, attr_assign.keys.first,attr_assign.values.first],
           :join_cond => {:component_component_id => :component__id},
           :cols => cols.include?(:component_component_id) ? cols : cols + [:component_component_id]
         }]
      row = Model.get_objects_from_join_array(model_handle.createMH(:component),base_sp_hash,join_array).first
      row && row[:attribute]
    end

    def destroy_and_delete()
      update_object!(:external_ref)
      suceeeded = CommandAndControl.destroy_node?(self)
      if suceeeded
        update_dangling_links()
        Model.delete_instance(id_handle())
      end
    end

    def update_dangling_links()
      dangling_links_info_cmps = get_objs(:cols => [:dangling_input_links_from_components])
      dangling_links_info_nodes = get_objs(:cols => [:dangling_input_links_from_nodes])

      #TODO: if only processing external links, more efficeint to filter in sql query
      ndx_dangling_links_info = Hash.new
      (dangling_links_info_cmps + dangling_links_info_nodes).each do |r|
        link = r[:all_input_links]
        if link[:type] == "external"
          attr_id = link[:input_id]
          p = ndx_dangling_links_info[attr_id] ||= {:input_attribute => r[:input_attribute], :other_links => Array.new}
          new_el = {
            :attribute_link_id => link[:id], 
            :index_map => link[:index_map], 
          }
          if link[:id] == r[:attribute_link][:id]
            p[:deleted_link] = new_el
          else
            p[:other_links] << new_el
          end
        end
      end
      attr_mh = model_handle(:attribute)
      #update attribles connected to dangling links on input side
      updated_attrs = AttributeUpdateDerivedValues.update_for_delete_links(attr_mh,ndx_dangling_links_info.values)
      #add state changes for updated attributes and see if any connected attributes
      Attribute.propagate_and_optionally_add_state_changes(attr_mh,updated_attrs,:add_state_changes => true)
    end
    private :update_dangling_links

    def get_project()
      get_objects_col_from_sp_hash(:cols => [:project]).first
    end

    def self.get_ports(id_handles)
      get_objs_in_set(id_handles,{:cols => [:ports]},{:keep_ref_cols => true}).map{|r|r[:port]}
    end

    def get_ports(*types)
      port_list = self.class.get_ports([id_handle])
      i18n = get_i18n_mappings_for_models(:component,:attribute)
      port_list.map{|port|port.filter_and_process!(i18n,*types)}.compact
    end

    def self.get_port_links(id_handles,*port_types)
      input_port_rows =  get_objs_in_set(id_handles,:columns => [:id, :display_name, :input_port_link_info]).select do |r|
        port_types.include?((r[:port]||{})[:type])
      end
      #TODO: implement using PortLink.common_columns and materialize
      input_port_rows.each do |r|
        r[:port_link][:ui] ||= {
          :type => R8::Config[:links][:default_type],
          :style => R8::Config[:links][:default_style]
        }
      end
      
      output_port_rows =  get_objs_in_set(id_handles,:columns => [:id, :display_name, :output_port_link_info]).select do |r|
        port_types.include?((r[:port]||{})[:type])
      end
      #TODO: implement using PortLink.common_columns and materialize
      output_port_rows.each do |r|
        r[:port_link][:ui] ||= {
          :type => R8::Config[:links][:default_type],
          :style => R8::Config[:links][:default_style]
        }
      end

      return Array.new if input_port_rows.empty? and output_port_rows.empty?

      indexed_ret = Hash.new
      input_port_rows.each do |r|
        id = r[:id]
        indexed_ret[id] ||= r.subset(:id, :display_name).merge(:input_port_links => Array.new, :output_port_links => Array.new)
        indexed_ret[id][:input_port_links] << r[:port_link]
      end
      output_port_rows.each do |r|
        id = r[:id]
        indexed_ret[id] ||= r.subset(:id, :display_name).merge(:output_port_links => Array.new, :output_port_links => Array.new)
        indexed_ret[id][:output_port_links] << r[:port_link]
      end
      indexed_ret.values
    end

    def self.get_output_attrs_to_l4_input_ports(id_handles)
      rows = get_objs_in_set(id_handles,{:cols => [:output_attrs_to_l4_input_ports]},{:keep_ref_cols => true})
      return Hash.new if rows.empty?
      #restructure so that get mapping from attribute_id to port
      ret = Hash.new
      rows.each do |row|
        attr_id = row[:port_external_output][:external_attribute_id]
        ret[attr_id] ||= Array.new
        ret[attr_id] << row[:port_l4_input]
      end
      ret
    end

    def self.get_violations(id_handles)
      get_objs_in_set(id_handles,{:cols => [:violations]}).map{|r|r[:violation]}
    end

    def get_ui_info(datacenter)
      datacenter_id_sym = datacenter[:id].to_s.to_sym
      node_id_sym = self[:id].to_s.to_sym
      #TODO: hack assumes that canm just take position from first node[:u1]
      ((datacenter[:ui]||{})[:items]||{})[node_id_sym] || (self[:ui]||{})[datacenter_id_sym] || (self[:ui]||{}).values.first
    end

    def update_ui_info!(ui,datacenter)
      datacenter_id_sym = datacenter[:id].to_s.to_sym
      node_id_sym = self[:id].to_s.to_sym
      self[:ui] ||= Hash.new
      self[:ui][datacenter_id_sym] = ui
    end

    def get_users()
      node_user_list = get_objects_from_sp_hash(:columns => [:users])
      user_list = Array.new
      #TODO: just putting in username, not uid or gid
      node_user_list.map do |u|
        attr = u[:attribute]
        val = attr[:value_asserted]||attr[:value_derived]
        (val and attr[:display_name] == "username") ? {:id => attr[:id], :username => val, :avatar_filename => 'generic-user-male.png'} : nil 
      end.compact
    end

    def get_applications()
      app_hash_list = get_objects_col_from_sp_hash({:columns => [:applications]},:component)

      i18n = get_i18n_mappings_for_models(:component)
      app_hash_list.map do |component|
        name = component[:display_name]
        cmp_i18n = i18n_string(i18n,:component,name)
        component_el = {:id => component[:id], :name =>  name, :i18n => cmp_i18n}
        component_icon_fn = ((component[:ui]||{})[:images]||{})[:tnail]
        component_el.merge(component_icon_fn ? {:component_icon_filename => component_icon_fn} : {})
      end
    end

    def get_node_service_checks()
      return Array.new if get_objects_from_sp_hash(:columns => [:monitoring_agents]).empty?

      #TODO: i18n treatment of service check names
      get_objects_col_from_sp_hash({:columns => [:monitoring_items__node]},:monitoring_item)
    end
    def get_component_service_checks()
      return Array.new if get_objects_from_sp_hash(:columns => [:monitoring_agents]).empty?
      #TODO: i18n treatment of service check names
      i18n = get_i18n_mappings_for_models(:component)

      get_objects_from_sp_hash(:columns => [:monitoring_items__component]).map do |r|
        cmp_name = r[:component][:display_name]
        cmp_info = {:component_name => cmp_name,:component_i18n => i18n_string(i18n,:component,cmp_name) }
        r[:monitoring_item].merge(cmp_info)
      end
    end

    #returns external attribute links and port links
    #returns [connected_links,dangling_links]
    def self.get_external_connected_links(id_handles)
      port_link_ret = get_conn_port_links(id_handles)
      attr_link_ret = get_conn_external_attr_links(id_handles)
      [port_link_ret[0]+attr_link_ret[0],port_link_ret[1]+attr_link_ret[1]]
    end

    #return ports links 
    #returns [connected_links,dangling_links]
    def self.get_conn_port_links(id_handles,opts={})
      ret = [Array.new,Array.new]
      in_port_cols = [:id, :display_name, :input_port_links]
      ndx_in_links = Hash.new
      get_objs_in_set(id_handles,{:columns => in_port_cols}).each do |r|
        link = r[:port_link]
        ndx_in_links[link[:id]] = link 
      end

      out_port_cols = [:id, :display_name, :output_port_links]
      ndx_out_links = Hash.new
      get_objs_in_set(id_handles,{:columns => out_port_cols}).each do |r|
        link = r[:port_link]
        ndx_out_links[link[:id]] = link 
      end

      return ret if ndx_in_links.empty? and ndx_out_links.empty?

      connected_links = (ndx_in_links.keys & ndx_out_links.keys).map{|id|ndx_in_links[id]}

      dangling_links = (ndx_in_links.keys - ndx_out_links.keys).map{|id|ndx_in_links[id]}
      dangling_links += (ndx_out_links.keys - ndx_in_links.keys).map{|id|ndx_out_links[id]}
      [connected_links,dangling_links]
    end

    #return externally connected attribute links
    #returns [connected_links,dangling_links]
    def self.get_conn_external_attr_links(id_handles)
      ret = [Array.new,Array.new]

      ndx_in_links = get_objs_in_set(id_handles,:cols => [:id,:input_attribute_links_cmp]).inject({}) do |h,r|
        link = r[:attribute_link]
        link[:type] == "external" ? h.merge(link[:id] => link) : h
      end
      ndx_in_links = get_objs_in_set(id_handles,:cols => [:id,:input_attribute_links_node]).inject(ndx_in_links) do |h,r|
        link = r[:attribute_link]
        link[:type] == "external" ? h.merge(link[:id] => link) : h
      end

      ndx_out_links = get_objs_in_set(id_handles,:cols => [:id,:output_attribute_links_cmp]).inject({}) do |h,r|
        link = r[:attribute_link]
        link[:type] == "external" ? h.merge(link[:id] => link) : h
      end
      ndx_out_links = get_objs_in_set(id_handles,:cols => [:id,:output_attribute_links_node]).inject(ndx_out_links) do |h,r|
        link = r[:attribute_link]
        link[:type] == "external" ? h.merge(link[:id] => link) : h
      end

      return ret if ndx_in_links.empty? and ndx_out_links.empty?

      connected_links = (ndx_in_links.keys & ndx_out_links.keys).map{|id|ndx_in_links[id]}

      dangling_links = (ndx_in_links.keys - ndx_out_links.keys).map{|id|ndx_in_links[id]}
      dangling_links += (ndx_out_links.keys - ndx_in_links.keys).map{|id|ndx_out_links[id]}
      [connected_links,dangling_links]
    end

    #TODO: quick hack
    def self.get_wspace_display(id_handle)
      node_id = IDInfoTable.get_id_from_id_handle(id_handle)
      node_mh = id_handle.createMH(:model_name => :node)
      node = get_objects(node_mh,{:id => node_id}).first

      component_mh = node_mh.createMH(:model_name => :component)
      component_ds = get_objects_just_dataset(component_mh,{:node_node_id => node_id})
      attr_where_clause = {:is_port => true}
      #TODO: can prune what fields included
      attr_fs = Model::FieldSet.default(:attribute).with_added_cols(:component_component_id)
      attribute_mh = node_mh.createMH(:model_name => :attribute)
      attribute_ds = get_objects_just_dataset(attribute_mh,attr_where_clause,FieldSet.opt(attr_fs))
      components = component_ds.graph(:left_outer,attribute_ds,{:component_component_id => :id}).all
      node.merge(:component => components)
    end
    #######################
#TODO: may be aqble to deprecate most or all of below
      ### helpers
      def ds_attributes(attr_list)
        [:ds_attributes]
      end
      #TODO: rename subobject to sub_object
      def is_ds_subobject?(relation_type)
        false
      end


      ##### Actions
#TODO: need tp fix up below
      def self.get_node_attribute_values(id_handle,opts={})
	c = id_handle[:c]
        node_obj = get_object(id_handle,opts)
        raise Error.new("node associated with (#{id_handle}) not found") if node_obj.nil? 	
	ret = node_obj.get_direct_attribute_values(:value) || {}

	cmps = node_obj.get_objects_associated_components()
	cmps.each{|cmp|
	  ret[:component]||= {}
	  cmp_ref = cmp.get_qualified_ref.to_sym
	  ret[:component][cmp_ref] = 
	    cmp[:external_ref] ? {:external_ref => cmp[:external_ref]} : {}
	  values = cmp.get_direct_attribute_values(:value,{:attr_include => [:external_ref]})
	  ret[:component][cmp_ref][:attribute] = values if values 
        }
        ret
      end

    #######

#TODO: should this be more generic and centralized?
    def get_objects_associated_components()
      assocs = Model.get_objects(ModelHandle.new(@c,:assoc_node_component),:node_id => self[:id])
      return [] if assocs.nil?
      assocs.map{|assoc|Model.get_object(IDHandle[:c=>@c,:guid => assoc[:component_id]])}
    end

#TODO: should be centralized
    def get_contained_attribute_ids(opts={})
      get_directly_contained_object_ids(:attribute)||[]
    end

    def get_direct_attribute_values(type,opts={})
      parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
      attr_val_array = Model.get_objects(ModelHandle.new(@c,:attribute),nil,:parent_id => parent_id)
      return nil if attr_val_array.nil?
      return nil if attr_val_array.empty?
      hash_values = {}
      attr_type = {:asserted => :value_asserted, :derived => :value_derived, :value => :attribute_value}[type]
      attr_val_array.each{|attr|
        hash_values[attr.get_qualified_ref.to_sym] =
          {:value => attr[attr_type],:id => attr[:id]}
      }
      {:attribute => hash_values}
    end

    def get_obj_with_common_cols()
      common_cols =  self.class.common_columns()
      ret = get_objs(:cols => common_cols).first
      ret.materialize!(common_cols)
    end

  end
end

module XYZ
  class NodeInterface < Model
#    set_relation_name(:node,:interface)

    ### object access functions
    #######################
  end
end



