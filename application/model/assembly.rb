r8_nested_require('assembly','attribute_pattern')
r8_nested_require('assembly','import_export_common')
#TODO: deprecate: r8_nested_require('assembly','export')
r8_nested_require('assembly','import')
module XYZ
  class Assembly < Component
    r8_nested_require('assembly','content')
    r8_nested_require('assembly','template')
    r8_nested_require('assembly','instance')
    #TODO: deprecate include AssemblyExportMixin
    include AssemblyImportMixin
    extend AssemblyImportClassMixin

    def self.create_library_template(library_idh,node_idhs,assembly_name,service_module_name,icon_info,version=nil)
      #first make sure that all referenced components have updated modules in the library
      ws_branches = ModuleBranch.get_component_workspace_branches(node_idhs)
      augmented_lib_branches = ModuleBranch.update_library_from_workspace?(ws_branches)

      #1) get a content object, 2) modify, and 3) persist
      port_links,dangling_links = Node.get_conn_port_links(node_idhs)
      #TODO: raise error to user if dangling link
      Log.error("dangling links #{dangling_links.inspect}") unless dangling_links.empty?

      service_module_branch = ServiceModule.get_module_branch(library_idh,service_module_name,version)

      assembly_instance =  Assembly::Instance.create_container_for_clone(library_idh,assembly_name,service_module_name,service_module_branch,icon_info)
      assembly_instance.add_content_for_clone!(library_idh,node_idhs,port_links,augmented_lib_branches)
      assembly_instance.create_assembly_template(library_idh,service_module_branch)
    end

    def info(subtype)
      nested_virtual_attr = (subtype == :template ? :template_nodes_and_cmps_summary : :nested_nodes_and_cmps_summary)
      sp_hash = {
        :cols => [:id, :display_name,:component_type,nested_virtual_attr]
      }
      assembly_info = get_objs(sp_hash)
      self.class.list_aux(assembly_info).first
    end

    def self.list_from_library(assembly_mh,opts={})
      sp_hash = {
        :cols => [:id, :display_name,:component_type,:template_nodes_and_cmps_summary],
        :filter => [:and, [:eq, :type, "composite"], [:neq, :library_library_id, nil], opts[:filter]].compact
      }
      assembly_rows = get_objs(assembly_mh,sp_hash)
      get_attrs = (opts[:detail_level] and [opts[:detail_level]].flatten.include?("attributes")) 
      attr_rows = get_attrs ? get_template_component_attributes(assembly_mh,assembly_rows) : []
      list_aux(assembly_rows,attr_rows)
    end

    def self.list_from_target(assembly_mh,opts={})
      target_idh = opts[:target_idh]
      target_filter = (target_idh ? [:eq, :datacenter_datacenter_id, target_idh.get_id()] : [:neq, :datacenter_datacenter_id, nil])
      sp_hash = {
        :cols => [:id, :display_name,:nested_nodes_and_cmps_summary],
        :filter => [:and, [:eq, :type, "composite"], target_filter]
      }
      assembly_rows = get_objs(assembly_mh,sp_hash)
      get_attrs = (opts[:detail_level] and [opts[:detail_level]].flatten.include?("attributes")) 
      attr_rows = get_attrs ? get_default_component_attributes(assembly_mh,assembly_rows) : []
      add_execution_status_to_list_from_target!(assembly_rows,assembly_mh)
      list_aux(assembly_rows,attr_rows)
    end

    def set_attributes(pattern,value)
      ret = Array.new
      pattern = AssemblyAttributePattern.create(pattern)
      attr_idhs = pattern.ret_attribute_idhs(id_handle())
      return ret if attr_idhs.empty?

      attr_mh = model_handle(:attribute)
      attribute_rows = attr_idhs.map{|idh|{:id => idh.get_id(),:value_asserted => value}}
      Attribute.update_and_propagate_attributes(attr_mh,attribute_rows)
      attr_idhs
    end

    def list_smoketests()
      sp_hash = {
        :cols => [:nested_nodes_and_cmps_summary]
      }
      nodes_and_cmps = get_objs(sp_hash)
      nodes_and_cmps.map{|r|r[:nested_component]}.select{|cmp|cmp[:basic_type] == "smoketest"}.map{|cmp|Aux::hash_subset(cmp,[:id,:display_name,:description])}
    end

    def self.meta_filename(assembly_name)
      "#{assembly_name}.assembly.json"
    end
    def self.meta_filename_regexp()
      /assembly.json$/
    end

    def self.ret_component_type(service_module_name,assembly_name)
      "#{service_module_name}__#{assembly_name}"
    end
    def self.pretty_print_name(assembly)
      assembly[:component_type] ? assembly[:component_type].gsub(/__/,"::") : assembly[:display_name]
    end

    class << self
      def list_aux(assembly_rows,attr_rows=[])
        ndx_attrs = Hash.new
        attr_rows.each do |attr|
          if attr[:attribute_value]
            (ndx_attrs[attr[:component_component_id]] ||= Array.new) << attr
          end
        end
        ndx_ret = Hash.new
        assembly_rows.each do |r|
          #TODO: hack to create a Assembly object (as opposed to row which is component); should be replaced by having 
          #get_objs do this (using possibly option flag for subtype processing)
          pntr = ndx_ret[r[:id]] ||= r.id_handle.create_object().merge(:display_name => pretty_print_name(r), :execution_status => r[:execution_status],:ndx_nodes => Hash.new)
          node_id = r[:node][:id]
          unless node = pntr[:ndx_nodes][node_id] 
            node = pntr[:ndx_nodes][node_id] = {
              :node_name => r[:node][:display_name], 
              :node_id => node_id, 
              :components => Array.new
            }
            node[:external_ref] = r[:node][:external_ref] if r[:node][:external_ref]
            node[:os_type] = r[:node][:os_type] if r[:node][:os_type]
          end
          cmp_hash = r[:nested_component]
          if cmp_type =  cmp_hash[:component_type] && cmp_hash[:component_type].gsub(/__/,"::")
            if attrs = ndx_attrs[r[:nested_component][:id]]
              processed_attrs = attrs.map do |attr|
                proc_attr = {:attribute_name => attr[:display_name], :value => attr[:attribute_value]}
                proc_attr[:override] = true if attr[:is_instance_value]
                proc_attr
              end
              cmp = {:component_name => cmp_type, :attributes => processed_attrs}
            elsif not attr_rows.empty?
              cmp = {:component_name => cmp_type}
            else
              cmp = cmp_type
            end
            node[:components] << cmp
          end
        end

        ndx_ret.values.map do |r|
          r.slice(:id,:display_name,:execution_status).merge(:nodes => r[:ndx_nodes].values)
        end
      end
     private
      def add_execution_status_to_list_from_target!(assembly_rows,assembly_mh)
        sp_hash = {
          :cols => [:id,:started_at,:assembly_id,:status],
          :filter => [:oneof,:assembly_id,assembly_rows.map{|r|r[:id]}]
        }
        ndx_task_rows = Hash.new
        get_objs(assembly_mh.createMH(:task),sp_hash).each do |task|
          assembly_id = task[:assembly_id]
          if pntr = ndx_task_rows[assembly_id]
            if task[:started_at] > pntr[:started_at] 
              ndx_task_rows[assembly_id] =  task.slice(:status,:started_at)
            end
          else
            ndx_task_rows[assembly_id] = task.slice(:status,:started_at)
          end
        end
        assembly_rows.each{|r|r[:execution_status] = (ndx_task_rows[r[:id]] && ndx_task_rows[r[:id]][:status])||"staged"} 
        assembly_rows
      end

      def create_library_template_obj(library_idh,assembly_name,service_module_name,module_branch,icon_info)
        create_row = {
          :library_library_id => library_idh.get_id(),
          :ref => "#{service_module_name}-#{assembly_name}",
          :display_name => assembly_name,
          :ui => icon_info,
          :type => "composite",
          :module_branch_id => module_branch[:id]
        }
        assembly_mh = library_idh.create_childMH(:component)
        create_from_row(assembly_mh,create_row, :convert => true)
      end

      def get_template_component_attributes(assembly_mh,template_assembly_rows,opts={})
        #get attributes on templates (these are defaults)
        ret = get_default_component_attributes(assembly_mh,template_assembly_rows,opts)
        return ret unless R8::Config[:use_node_bindings]
        #get attribute overrides
        sp_hash = {
          :cols => [:id,:display_name,:attribute_value,:attribute_template_id],
          :filter => [:oneof, :component_ref_id,template_assembly_rows.map{|r|r[:component_ref][:id]}]
        }
        attr_override_rows = Model.get_objs(assembly_mh.createMH(:attribute_override),sp_hash)
        unless attr_override_rows.empty?
          ndx_attr_override_rows = attr_override_rows.inject(Hash.new) do |h,r|
            h.merge(r[:attribute_template_id] => r)
          end
          ret.each do |r|
            if override = ndx_attr_override_rows[r[:id]]
              r.merge!(:attribute_value => override[:attribute_value], :is_instance_value => true)
            end
          end
        end
        ret
      end

      def get_default_component_attributes(assembly_mh,assembly_rows,opts={})
        #by defualt do not include derived values
        cols = [:id,:display_name,:value_asserted,:component_component_id,:is_instance_value] + (opts[:include_derived] ? [:value_derived] : [])
        sp_hash = {
          :cols => cols,
          :filter => [:oneof, :component_component_id,assembly_rows.map{|r|r[:nested_component][:id]}]
        }
        Model.get_objs(assembly_mh.createMH(:attribute),sp_hash)
      end
    end

    def self.delete(assembly_idh,subtype=nil)
      subtype ||= (is_template?(assembly_idh) ? :template : :instance) 
      if subtype == :template
        delete_template(assembly_idh)
      else
        delete_instance_and_destroy_its_nodes(assembly_idh)
      end
    end

    def self.is_template?(assembly_idh)
      assembly_idh.create_object().is_template?()
    end
    def is_template?()
      not update_object!(:library_library_id)[:library_library_id].nil?
    end
   private
    def self.delete_template(assembly_idh)
      #need to explicitly delete nodes, but not components since node's parents are not the assembly, while compoennt's parents are the nodes
      #do not need to delete port links which use a cascade foreign keyy
      sp_hash = {
        :cols => [:id, :nodes],
        :filter => [:eq, :id, assembly_idh.get_id]
      }
      node_idhs = get_objs(assembly_idh.createMH(),sp_hash).map{|r|r[:node].id_handle()}
      Model.delete_instances(node_idhs)
      Model.delete_instance(assembly_idh)
    end
   
    def self.delete_instance_and_destroy_its_nodes(assembly_idh)
      #TODO: need to refine to handle case where node hosts multiple assemblies or native components; before that need to modify node isnatnce
      #repo so can point to multiple assembly instances
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:eq, :assembly_id, assembly_idh.get_id]
      }
      assembly_nodes = get_objs(assembly_idh.createMH(:node),sp_hash)
      assembly_nodes.map{|r|r.destroy_and_delete()}
      Model.delete_instance(assembly_idh)
    end
   public

    #### for cloning
    def add_model_specific_override_attrs!(override_attrs,target_obj)
      override_attrs[:display_name] ||= SQL::ColRef.qualified_ref 
      override_attrs[:updated] ||= false
    end

    ##############
    #TODO: looks like callers dont need all teh detail; might just provide summarized info or instead pass arg that specifies sumamry level
    #also make optional whether materialize
    def get_node_assembly_nested_objects()
      ndx_nodes = Hash.new
      sp_hash = {:cols => [:nested_nodes_and_cmps]}
      node_col_rows = get_objs(sp_hash)
      node_col_rows.each do |r|
        n = r[:node].materialize!(Node.common_columns)
        node = ndx_nodes[n[:id]] ||= n.merge(:components => Array.new)
        node[:components] << r[:nested_component].materialize!(Component.common_columns())
      end

      nested_node_ids = ndx_nodes.keys
      sp_hash = {
        :cols => Port.common_columns(),
        :filter => [:oneof, :node_node_id, nested_node_ids]
      }
      port_rows = Model.get_objs(model_handle(:port),sp_hash)
      port_rows.each do |r|
        node = ndx_nodes[r[:node_node_id]]
        (node[:ports] ||= Array.new) << r.materialize!(Port.common_columns())
      end
      sp_hash = {
        :cols => PortLink.common_columns(),
        :filter => [:eq, :assembly_id, id()]
      }
      port_links = Model.get_objs(model_handle(:port_link),sp_hash)
      port_links.each{|pl|pl.materialize!(PortLink.common_columns())}

      {:nodes => ndx_nodes.values, :port_links => port_links}
    end

    def is_assembly?()
      true
    end
    def assembly_type()
      #TODO: stub; may use basic_type to distinguish between component and node assemblies
      :node
    end
    def is_base_component?()
      nil
    end

    #TODO: can we avoid explicitly pacing this here
    def self.db_rel()
      Component.db_rel()
    end

    def get_component_with_attributes_unraveled(attr_filters={})
      attr_vc = "#{assembly_type()}_assembly_attributes".to_sym
      sp_hash = {:columns => [:id,:display_name,:component_type,:basic_type,attr_vc]}
      component_and_attrs = get_objects_from_sp_hash(sp_hash)
      return nil if component_and_attrs.empty?
      sample = component_and_attrs.first
      #TODO: hack until basic_type is populated
      #component = sample.subset(:id,:display_name,:component_type,:basic_type)
      component = sample.subset(:id,:display_name,:component_type).merge(:basic_type => "#{assembly_type()}_assembly")
      node_attrs = {:node_id => sample[:node][:id], :node_name => sample[:node][:display_name]} 
      filtered_attrs = component_and_attrs.map do |r|
        attr = r[:attribute]
        if attr and not attribute_is_filtered?(attr,attr_filters)
          cmp = r[:sub_component]
          cmp_attrs = {:component_type => cmp[:component_type],:component_name => cmp[:display_name]}
          attr.merge(node_attrs).merge(cmp_attrs)
        end
      end.compact
      attributes = AttributeComplexType.flatten_attribute_list(filtered_attrs)
      component.merge(:attributes => attributes)
    end
  end
end
