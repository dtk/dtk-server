r8_nested_require('target','clone')

module XYZ
  class Target < Model
    include TargetCloneMixin
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
       :ui
      ]
    end
    ### virtual column defs
    def name()
      self[:display_name]
    end

    def type()
      self[:type]
    end

    def is_template()
      (self[:type] == 'template')
    end

    ######### Model apis
    def info_about(about)
      case about
       when :assemblies
         Assembly::Instance.list(model_handle(:component),:target_idh => id_handle())
       when :nodes
         Node.list(model_handle(:node),:target_idh => id_handle())
      else
        raise Error.new("TODO: not implemented yet: processing of info_about(#{about})")
      end
    end

    def self.check_valid_id(model_handle,id)
      check_valid_id_helper(model_handle,id,[:eq, :id, id])
    end

    #takes values from default aside from ones specfically given in argument
    def self.create_from_default(project_idh,display_name,params_hash)
      target_mh = project_idh.createMH(:target) 
      unless default = get_default_target(target_mh,[:iaas_type,:iaas_properties,:type])
        raise ErrorUsage.new("Cannot find default target")
      end
      ref = display_name.downcase.gsub(/ /,"-")
      row = default.merge(:ref => ref, :display_name => display_name).merge(params_hash)
      create_from_row(target_mh,row,:convert => true)
    end
   
    def self.get_default_target(target_mh,cols=[]) 
      cols = [:id,:display_name,:group_id] if cols.empty?
      sp_hash = {
        :cols => cols,
        :filter => [:eq,:is_default_target,true]
      }
      Model.get_obj(target_mh,sp_hash)
    end
      
    def update_ui_for_new_item(new_item_id)
      update_object!(:ui)
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
      project_id = update_object!(:project_id)[:project_id]
      id_handle(:id => project_id,:model_name => :project).create_object()
    end

    def get_node_config_changes()
      nodes = get_objs(:cols => [:nodes]).map{|r|r[:node]}
      ndx_changes = StateChange.get_ndx_node_config_changes(id_handle)
      nodes.inject({}){|h,n|h.merge(n.id => ndx_changes[n.id]||StateChange.node_config_change__no_changes())}
    end

    def get_iaas_type()
      update_object!(:iaas_type)[:iaas_type]
    end

    # returns aws params if pressent in iaas properties
    def get_aws_compute_params()
      iaas_props = update_object!(:iaas_properties)[:iaas_properties]
      if iaas_props && (aws_key = iaas_props[:key]) && (aws_secret = iaas_props[:secret])
        return { :aws_access_key_id => aws_key, :aws_secret_access_key => aws_secret }
      end

      return nil
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

