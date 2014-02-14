module DTK
  class Assembly
    module ListMixin
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

      def pretty_print_name(opts={})
        self.class.pretty_print_name(self,opts={})
      end

    end

    module ListClassMixin
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
          pntr = ndx_ret[r[:id]] ||= r.prune_with_values(:display_name => r.pretty_print_name(pp_opts), :execution_status => r[:execution_status],:ndx_nodes => Hash.new)
          if module_branch_id = r[:module_branch_id]
            pntr[:module_branch_id] ||= module_branch_id 
          end
          if target = (r[:target]||{})[:display_name]
            pntr[:target] ||= target
          end
          
          if version = pretty_print_version(r)
            pntr.merge!(:version => version)
          end
          if template = r[:assembly_template]
            #just triggers for assembly instances; indicates the assembly templaet that spawned it
            pntr.merge!(:assembly_template => Template.pretty_print_name(template,:version_suffix => true))
          end
          if created_at = r[:created_at]
            pntr.merge!(:created_at => created_at) 
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
          r.merge(:op_status => op_status,:nodes => nodes).slice(:id,:display_name,:op_status,:execution_status,:module_branch_id,:version,:assembly_template,:nodes,:created_at,:target)
        end
        
        unsorted.sort{|a,b|a[:display_name] <=> b[:display_name]}
      end

     private
      def list_aux__component_template(r)
        r[:component_template]||r[:nested_component]||{}
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

    end
  end
end
