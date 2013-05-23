#TODO: finish moving the fns and mixins that relate just to template or instance to these files
r8_nested_require('assembly','import_export_common')
module DTK
  class Assembly < Component
    r8_nested_require('assembly','template')
    r8_nested_require('assembly','instance')
    ### standard get methods
    def get_assembly_level_attributes(filter_proc=nil)
      sp_hash = {
        :cols => [:id,:display_name,:attribute_value,:data_type],
        :filter => [:eq,:component_component_id, id()]
      }
      ret = Model.get_objs(model_handle(:attribute),sp_hash)
      if filter_proc
        ret.select{|r| filter_proc.call(r)}
      else
        ret
      end
    end

    def get_port_links(opts={})
      filter = [:eq,:assembly_id,id()]
      if opts[:filter]
        filter = [:and,filter,opts[:filter]]
      end
      sp_hash = {
        :cols => opts[:cols]||PortLink.common_columns(),
        :filter => filter
      }
      Model.get_objs(model_handle(:port_link),sp_hash)
    end      

    #augemented with the ports and nodes
    def get_augmented_port_links()
      rows = get_objs(:cols => [:augmented_port_links])
      rows.map do |r|
        r[:port_link].merge(r.slice(:input_port,:output_port,:input_node,:output_node))
      end
    end

    #MOD_RESTRUCT: this must be removed or changed to reflect more advanced relationship between component ref and template
    def self.get_component_templates(assembly_mh,filter=nil)
      sp_hash = {
        :cols => [:id, :display_name,:component_type,:component_templates],
        :filter => [:and, [:eq, :type, "composite"], [:neq, :library_library_id, nil], filter].compact
      }
      assembly_rows = get_objs(assembly_mh,sp_hash)
      assembly_rows.map{|r|r[:component_template]}
    end

    #this can be overwritten
    def self.get_component_attributes(assembly_mh,template_assembly_rows,opts={})
      Array.new
    end

    ### end: standard get methods

    def info(node_id=nil, component_id=nil, attribute_id=nil)
      opts = {}
      nested_virtual_attr = (kind_of?(Template) ? :template_nodes_and_cmps_summary : :instance_nodes_and_cmps_summary)
      sp_hash = {
        :cols => [:id, :display_name,:component_type,nested_virtual_attr]
      }
      assembly_rows = get_objs(sp_hash)
      # filter nodes by node_id if node_id is provided in request
      unless (node_id.nil? || node_id.empty?)
        assembly_rows = assembly_rows.select { |node| node[:node][:id] == node_id.to_i } 
        opts = {:component_info => true}
      end
      # filter nodes by component_id if component_id is provided in request
      unless (component_id.nil? || component_id.empty?)
        assembly_rows = assembly_rows.select { |node| node[:nested_component][:id] == component_id.to_i } 
        opts = {:component_info => true, :attribute_info => true}
      end

      # load attributes for assembly
      attr_rows = self.class.get_default_component_attributes(model_handle(), assembly_rows)

      # filter attributes by attribute_name if attribute_name is provided in request
      attr_rows = attr_rows.select { |attr| attr[:id] == attribute_id.to_i }  unless (attribute_id.nil? || attribute_id.empty?)
      
      # reconfigure response fields that will be returned to the client
      self.class.list_aux(assembly_rows,attr_rows, opts).first      
    end

    def self.get_default_component_attributes(assembly_mh,assembly_rows,opts={})
      #by defualt do not include derived values
      cols = [:id,:display_name,:value_asserted,:component_component_id,:is_instance_value] + (opts[:include_derived] ? [:value_derived] : [])
      sp_hash = {
        :cols => cols,
        :filter => [:oneof, :component_component_id,assembly_rows.map{|r|r[:nested_component][:id]}]
      }
      Model.get_objs(assembly_mh.createMH(:attribute),sp_hash)
    end

    def set_attributes(av_pairs)
      Attribute::Pattern::Assembly.set_attributes(self,av_pairs)
    end

    def self.ret_component_type(service_module_name,assembly_name)
      "#{service_module_name}__#{assembly_name}"
    end
    def self.pretty_print_name(assembly,opts={})
      ret = 
        if cmp_type = assembly[:component_type] 
          if opts[:no_module_prefix]
            assembly[:component_type].gsub(/^.+__/,"")
          else
            assembly[:component_type].gsub(/__/,"::")
          end
        else 
          assembly[:display_name]
      end

      if opts[:version_suffix] 
        version = pretty_print_version(assembly)
        version ? "#{ret}-v#{version}" : ret
      else
        ret
      end
    end

    def self.pretty_print_version(assembly)
      assembly[:version] && ModuleBranch.version_from_version_field(assembly[:version])
    end

    def is_stopped?
      filtered_nodes = get_nodes(:id,:admin_op_status).select { |node| node[:admin_op_status] == 'stopped' }
      return (filtered_nodes.size > 0)
    end

    def are_nodes_running?
      nodes = get_nodes(:id)
      running_nodes = Task::Status::Assembly.get_active_nodes(model_handle())
      
      return false if running_nodes.empty?
      interrsecting_nodes = (running_nodes.map(&:id) & nodes.map(&:id))

      return !interrsecting_nodes.empty?
    end

    class << self
      def list_aux(assembly_rows,attr_rows=[],opts={})
        ndx_attrs = Hash.new

        if opts[:attribute_info] 
          attr_rows.each do |attr|
            if (attr[:attribute_value] && !attr[:attribute_value].empty?)
              (ndx_attrs[attr[:component_component_id]] ||= Array.new) << attr
            end
          end
        end

        ndx_ret = Hash.new
        pp_opts = Aux.hash_subset(opts,[:no_module_prefix])
        assembly_rows.each do |r|
          #TODO: hack to create a Assembly object (as opposed to row which is component); should be replaced by having 
          #get_objs do this (using possibly option flag for subtype processing)
          pntr = ndx_ret[r[:id]] ||= r.id_handle.create_object().merge(:display_name => pretty_print_name(r,pp_opts), :execution_status => r[:execution_status],:ndx_nodes => Hash.new)
          pntr.merge!(:module_branch_id => r[:module_branch_id]) if r[:module_branch_id]
          if version = pretty_print_version(r)
            pntr.merge!(:version => version)
          end
          if template = r[:assembly_template]
            #just triggers for assembly instances; indicates the assembly templaet that spawned it
            pntr.merge!(:assembly_template => Template.pretty_print_name(template,:version_suffix => true))
          end
          node_id = r[:node][:id]
          unless node = pntr[:ndx_nodes][node_id] 
            node = pntr[:ndx_nodes][node_id] = {
              :node_name  => r[:node][:display_name], 
              :node_id    => node_id,
              :components => Array.new
            }
            node[:admin_op_status] = r[:node][:admin_op_status] if r[:node][:admin_op_status]
            node[:external_ref]    = r[:node][:external_ref] if r[:node][:external_ref]
            node[:os_type]         = r[:node][:os_type] if r[:node][:os_type]
          end

          cmp_hash = list_aux__component_template(r)
          if cmp_type =  cmp_hash[:component_type] && cmp_hash[:component_type].gsub(/__/,"::")
            cmp = 
              if opts[:component_info]
                version = ModuleBranch.version_from_version_field(cmp_hash[:version])
                {:component_name => cmp_type,:component_id => cmp_hash[:id], :basic_type => cmp_hash[:basic_type], :description => cmp_hash[:description], :version => version}
              elsif not attr_rows.empty?
                {:component_name => cmp_type}
              else
                cmp_type
              end

            if attrs = ndx_attrs[list_aux__component_template(r)[:id]]
              processed_attrs = attrs.map do |attr|
                proc_attr = {:attribute_name => attr[:display_name], :value => attr[:attribute_value]}
                proc_attr[:override] = true if attr[:is_instance_value]
                proc_attr
              end
              cmp.merge!(:attributes => processed_attrs) if cmp.kind_of?(Hash)
            end
            node[:components] << cmp
          end
        end

        unsorted = ndx_ret.values.map do |r|
          op_status      = ''
          pending_status = nil
          stop_status    = nil

          r[:ndx_nodes].each do |node|
            if (status = node[1][:admin_op_status]).eql? "stopped"
              stop_status = "stopped"; break
            elsif status.eql? "pending"
              pending_status = "pending"
            end
          end

          op_status = stop_status||pending_status||"running"    

          r.slice(:id,:display_name,:execution_status,:module_branch_id,:version,:assembly_template).merge(:nodes => r[:ndx_nodes].values, :op_status => op_status)
        end
        
        unsorted.sort{|a,b|a[:display_name] <=> b[:display_name]}
      end

      #MOD_RESTRUCT: TODO: r[:nested_component] is temp until move over to assembly virtual attributes that use :component_template rather than :nested_component
      def list_aux__component_template(r)
        r[:component_template]||r[:nested_component]||{}
      end
      private :list_aux__component_template

      def internal_assembly_ref(service_module_name,assembly_name,version_field=nil)
        simple_assembly_ref = "#{service_module_name}-#{assembly_name}"
        internal_assembly_ref__add_version(simple_assembly_ref,version_field)
      end
      def internal_assembly_ref__add_version(assembly_ref,version_field=nil)
        version = (version_field && ModuleBranch.version_from_version_field(version_field))
        version_suffix = (version ? "--#{version}" : "")
        "#{assembly_ref}#{version_suffix}"
      end

    end

    def self.is_template?(assembly_idh)
      assembly_idh.create_object().is_template?()
    end
    def is_template?()
      not update_object!(:library_library_id)[:library_library_id].nil?
    end

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
      sp_hash = {:cols => [:instance_nodes_and_cmps]}
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
      port_links = get_port_links()
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
