#TODO: finish moving the fns and mixins that relate just to template or instance to these files
r8_nested_require('assembly','import_export_common')
module DTK
  class Assembly < Component
    r8_nested_require('assembly','template')
    r8_nested_require('assembly','instance')

    def self.create_from_component(cmp)
      cmp && create_from_id_handle(cmp.id_handle()).merge(cmp)
    end

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

    def get_service_module()
      get_obj_helper(:service_module)
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

    def get_matching_port_link(filter)
      opts = {:filter => filter, :ret_match_info => Hash.new}
      matches = get_augmented_port_links(opts)
      case matches.size
        when 1
          matches.first
        when 0
          raise ErrorUsage.new("Cannot find service link with condition (#{opts[:ret_match_info][:clause]})")
        else
          raise ErrorUsage.new("Multiple matching service links with condition (#{opts[:ret_match_info][:clause]})")
      end
    end
    #augmented with the ports and nodes; component_id is on ports
    def get_augmented_port_links(opts={})
      rows = get_objs(:cols => [:augmented_port_links])
      #TODO: remove when have all create port link calls set port_link display name to service type
      rows.each{|r|r[:port_link][:display_name] ||= r[:input_port].link_def_name()}  
      if filter = opts[:filter]
        post_filter = 
          if Aux.has_just_these_keys?(filter,[:port_link_id])
            port_link_id = filter[:port_link_id]
            if opts[:ret_match_info]
              opts[:ret_match_info][:clause] = "port_link_id = #{port_link_id.to_s}"
            end
            lambda{|r|r[:port_link][:id] == port_link_id}
          elsif Aux.has_just_these_keys?(filter,[:input_component_id])
            input_component_id = filter[:input_component_id]
            #not setting opts[:ret_match_info][:clause] because :input_component_id internally generated
            lambda{|r|r[:input_port][:component_id] == input_component_id}
          elsif Aux.has_just_these_keys?(filter,[:service_type,:input_component_id])
            input_component_id = filter[:input_component_id]
            service_type = filter[:service_type]
            #not including conjunct with :input_component_id because internally generated
            if opts[:ret_match_info]
              opts[:ret_match_info][:clause] = "service_type = '#{service_type}'"
            end
            lambda{|r|(r[:input_port][:component_id] == input_component_id) and (r[:port_link][:display_name] == service_type)}
          else
            raise Error.new("Unexpected filter (#{filter.inspect})")
          end
        rows.reject!{|r|!post_filter.call(r)}
      end
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
      self.class.list_aux(assembly_rows,attr_rows, {:print_form=>true}.merge(opts)).first      
    end

    def self.get_default_component_attributes(assembly_mh,assembly_rows,opts={})
      ret = Array.new
      cmp_ids = assembly_rows.map{|r|(r[:nested_component]||{})[:id]}.compact
      return ret if cmp_ids.empty?

      #by defalut do not include derived values
      cols = [:id,:display_name,:value_asserted,:component_component_id,:is_instance_value] + (opts[:include_derived] ? [:value_derived] : [])
      sp_hash = {
        :cols => cols,
        :filter => [:oneof, :component_component_id,cmp_ids]
      }
      Model.get_objs(assembly_mh.createMH(:attribute),sp_hash)
    end

    def set_attributes(av_pairs,opts={})
      attr_patterns = Attribute::Pattern::Assembly.set_attributes(self,av_pairs,opts)
    end

    def self.ret_component_type(service_module_name,assembly_name)
      "#{service_module_name}__#{assembly_name}"
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

    def pretty_print_name(opts={})
      self.class.pretty_print_name(self,opts={})
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
          pntr = ndx_ret[r[:id]] ||= r.id_handle.create_object().merge(:display_name => r.pretty_print_name(pp_opts), :execution_status => r[:execution_status],:ndx_nodes => Hash.new)
          pntr.merge!(:module_branch_id => r[:module_branch_id]) if r[:module_branch_id]
          if version = pretty_print_version(r)
            pntr.merge!(:version => version)
          end
          if template = r[:assembly_template]
            #just triggers for assembly instances; indicates the assembly templaet that spawned it
            pntr.merge!(:assembly_template => Template.pretty_print_name(template,:version_suffix => true))
          end

          if raw_node = r[:node]
            node_id = raw_node[:id]
            unless node = pntr[:ndx_nodes][node_id] 
              node = pntr[:ndx_nodes][node_id] = {
                :node_name  => raw_node[:display_name], 
                :node_id    => node_id,
                :os_type    => raw_node[:os_type],
                :admin_op_status => raw_node[:admin_op_status]
              }
              node.reject!{|k,v|v.nil?}
              if node_ext_ref = raw_node[:external_ref]
                node[:external_ref]  = (opts[:print_form] ? node_external_ref_print_form(node_ext_ref) : node_ext_ref) 
              end
              node[:components] = Array.new
            end
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
          nodes = r[:ndx_nodes].values
          op_status = (op_status(nodes) if respond_to?(:op_status))
          r.merge(:op_status => op_status,:nodes => nodes).slice(:id,:display_name,:op_status,:execution_status,:module_branch_id,:version,:assembly_template,:nodes)
        end
        
        unsorted.sort{|a,b|a[:display_name] <=> b[:display_name]}
      end

      def node_external_ref_print_form(node_ext_ref)
        ret = node_ext_ref.class.new()
        node_ext_ref.each_pair do |k,v|
          if [:dns_name].include?(k) 
            #no op
          elsif k == :private_dns_name and v.kind_of?(Hash)            
            ret[k] = v.values.first
          else
            ret[k] = v
          end
        end
        ret
      end
      private :node_external_ref_print_form

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
        if node = r[:node]
          n = node.materialize!(Node.common_columns)
          node = ndx_nodes[n[:id]] ||= n.merge(:components => Array.new)
          node[:components] << r[:nested_component].materialize!(Component.common_columns())
        end
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
    def assembly?(opts={})
      if opts[:subclass_object]
        self.class.create_assembly_subclass_object(self)
      else
        self
      end
    end
    def self.create_assembly_subclass_object(obj)
      obj.update_object!(:datacenter_datacenter_id)
      subclass_model_name = (obj[:datacenter_datacenter_id] ? :assembly_instance : :assembly_template)
      create_subclass_object(obj,subclass_model_name)
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
    def assembly_type()
      #TODO: stub; may use basic_type to distinguish between component and node assemblies
      :node
    end
    private :assembly_type
  end
end
