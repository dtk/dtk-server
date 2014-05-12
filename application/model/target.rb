module DTK
  class Target < Model
    r8_nested_require('target','clone')
    include TargetCloneMixin
    r8_nested_require('target','iaas_properties')
    r8_nested_require('target','instance')
    r8_nested_require('target','template')

    def model_name() #TODO: remove temp datacenter->target
      :datacenter
    end
    ##
    def self.common_columns()
      [
       :id,
       :display_name,
       :name,
       :description,
       :type,
       :iaas_type,
       :iaas_properties,
       :project_id,
       :is_default_target,
       :provider,
       :ui
      ]
    end

    def self.name_to_id(model_handle,name)
      filter = [:and, [:eq, :display_name, name], object_type_filter()]
      name_to_id_helper(model_handle,name,:filter => filter)
    end

    def self.check_valid_id(model_handle,id)
      filter = [:and, [:eq, :id, id], object_type_filter()]
      check_valid_id_helper(model_handle,id,filter)
    end

    def name()
      get_field?(:display_name)
    end

    def type()
      get_field?(:type)
    end

    def is_default?()
      get_field?(:is_default_target)
    end

    def info_about(about, opts={})
      case about
       when :assemblies
         opts.merge!(:target_idh => id_handle())
         Assembly::Instance.list(model_handle(:component), opts)
       when :nodes
         Node.list(model_handle(:node), :target_idh => id_handle())
      else
        raise Error.new("TODO: not implemented yet: processing of info_about(#{about})")
      end
    end

    def self.info(target_mh, id)
      target_info = Target.get(target_mh, id)
      target_info[:provider_name] = target_info[:provider][:display_name] if target_info[:provider]
      target_info
    end

    def self.check_valid_id(model_handle,id)
      check_valid_id_helper(model_handle,id,[:eq, :id, id])
    end

    def self.get(target_mh, id)
      sp_hash = {
        :cols => common_columns(),
        :filter => [:eq, :id, id]
      }
      get_obj(target_mh, sp_hash)
    end

    def self.get_default_target(target_mh,cols=[]) 
      cols = [:id,:display_name,:group_id] if cols.empty?
      sp_hash = {
        :cols => cols,
        :filter => [:eq,:is_default_target,true]
      }
      Model.get_obj(target_mh,sp_hash)
    end
      
    def self.set_default_target(target)
      current_default_target = get_default_target(target.model_handle(),[:display_name])
      if current_default_target.id == target.id
        raise ErrorUsage::Warning.new("Default target is already set to #{current_default_target[:display_name]}")
      end
      Transaction do
        current_default_target.update(:is_default_target => false)
        target.update(:is_default_target => true)
      end
      ResponseInfo.info("Default target changed from ?current_default_target to ?new_default_target",
                        :current_default_target => current_default_target,
                        :new_default_target => target)
    end

    def update_ui_for_new_item(new_item_id)
      update_obj!(:ui)
      target_ui = self[:ui]||{:items=>{}}
      target_ui[:items][new_item_id.to_s.to_sym] = {}
      update(:ui=>target_ui)
    end

    def get_ports(*types)
      port_list = get_objs(:cols => [:node_ports]).map do |r|
        component_id = (r[:link_def]||{})[:component_component_id]
        component_id ? r[:port].merge(:component_id => component_id) : r[:port]
      end
      i18n = get_i18n_mappings_for_models(:component,:attribute)
      port_list.map{|port|port.filter_and_process!(i18n,*types)}.compact
    end

    def get_node_members()
      get_objs(:cols => [:node_members]).map{|r|r[:node_member]}
    end

    def get_project()
      project_id = get_field?(:project_id)
      id_handle(:id => project_id,:model_name => :project).create_object()
    end

    def get_node_config_changes()
      nodes = get_objs(:cols => [:nodes]).map{|r|r[:node]}
      ndx_changes = StateChange.get_ndx_node_config_changes(id_handle)
      nodes.inject({}){|h,n|h.merge(n.id => ndx_changes[n.id]||StateChange.node_config_change__no_changes())}
    end

    ### TODO these should be moved to IAAS-spefic location
    def get_iaas_type()
      get_field?(:iaas_type)
    end

    def get_security_group()
      get_iaas_properties()[:security_group]
    end

    def get_region()
      get_iaas_properties()[:region]
    end

    def get_keypair_name()
      get_iaas_properties()[:keypair]
    end

    def get_security_group()
      get_iaas_properties()[:security_group]
    end

    # returns aws params if pressent in iaas properties
    def get_aws_compute_params()
      iaas_props = get_iaas_properties()
      if iaas_props && (aws_key = iaas_props[:key]) && (aws_secret = iaas_props[:secret])
        ret = { :aws_access_key_id => aws_key, :aws_secret_access_key => aws_secret }
        if region = iaas_props[:region]
          ret.merge!(:region => region)
        end
        ret
      end
    end

    ### TODO end: these should be moved to IAAS-spefic location

    def get_iaas_properties()
      update_object!(:iaas_properties,:parent_id)
      iaas_properties = self[:iaas_properties]
      if parent_id = self[:parent_id]
        parent_provider = id_handle(:id => parent_id).create_object(:model_name => :target_instance)
        if parent_iaas_properties = parent_provider.get_field?(:iaas_properties)
          #specific properties take precedence over the parent's
          iaas_properties = parent_iaas_properties.merge(iaas_properties||{})
        end
      end
      iaas_properties
    end

    def get_and_update_nodes_status()
      nodes = get_objs(:cols => [:nodes]).map{|r|r[:node]}
      nodes.inject({}){|h,n|h.merge(n.id => n.get_and_update_status!())}
    end

    def destroy_and_delete_nodes()
      nodes = get_objs(:cols => [:nodes]).map{|r|r[:node]}
      nodes.each{|n|n.destroy_and_delete()}
    end

    def get_violation_info(severity=nil)
      get_objs(:columns => [:violation_info]).map do |r|
        v = r[:violation]
        if severity.nil? or v[:severity] == severity
          v.merge(:target_node_display_name => (r[:node]||{})[:display_name])
        end
      end.compact
    end

    def add_item(source_id_handle,override_attrs={})
      #TODO: need to copy in avatar when hash["ui"] is non null
      override_attrs ||= {}
      source_obj = source_id_handle.create_object()
      clone_opts = source_obj.source_clone_info_opts()
      new_obj = clone_into(source_obj,override_attrs,clone_opts)
      new_obj && new_obj.id()
    end

    def self.get_port_links(id_handles,*port_types)
      return Array.new if id_handles.empty?

      node_id_handles = id_handles.select{|idh|idh[:model_name] == :node}
      if node_id_handles.size < id_handles.size
        models_not_treated = id_handles.reject{|idh|idh[:model_name] == :node}.map{idh|idh[:model_name]}.unique
        Log.error("Item list for Target.get_port_links has models not treated (#{models_not_treated.join(",")}; they will be ignored")
      end

      raw_link_list = Node.get_port_links(node_id_handles,*port_types)
      ndx_ret = Hash.new
      raw_link_list.each do |el|
        [:input_port_links,:output_port_links].each do |dir|
          (el[dir]||[]).each{|port_link|ndx_ret[port_link[:id]] ||= port_link}
        end
      end
      ndx_ret.values
    end

   private
    def sub_item_model_names()
      [:node]
    end
  end
  Datacenter = Target #TODO: remove temp datacenter->target
end

