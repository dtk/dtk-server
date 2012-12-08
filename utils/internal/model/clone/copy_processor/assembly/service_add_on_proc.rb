module DTK
  class Clone; class CopyProcessor; class Assembly
    class ServiceAddOnProc
      def initialize(service_add_on_info)
        if service_add_on_info
          @service_add_on = service_add_on_info[:service_add_on]
          @node_bindings = service_add_on_info[:service_add_on].get_service_node_bindings()
          @base_assembly = service_add_on_info[:base_assembly]
        else
          @service_add_on = nil
          @port_links = Array.new
          @base_assembly = nil
        end
      end
      attr_reader :node_bindings
      
      def get_mapped_nodes(create_override_attrs,create_opts)
        ret = Array.new
        return ret unless @service_add_on
        cols_needed = (create_opts[:returning_sql_cols]||[]) - create_override_attrs.keys
        unless missing = (cols_needed - [:ancestor_id]).empty?
          raise Error.new("Not implemented: get_mapped_nodes returning cols (#{missing.join(",")})")
        end
        sp_hash = {
          :cols => [:id,:group_id,:ancestor_id],
          :filter => [:and, [:eq,:assembly_id,@base_assembly[:id]],
                      [:oneof,:ancestor_id,@node_bindings.map{|nb|nb[:assembly_node_id]}]]
          
        }
        node_mh = @base_assembly.model_handle(:node)
        ret = Model.get_objs(node_mh,sp_hash)
        ndx_node_bindings = @node_bindings.inject(Hash.new){|h,nb|h.merge(nb[:assembly_node_id] => nb)}
        ret.each do |a|
          mapped_ancestor_id = ndx_node_bindings[a[:ancestor_id]][:sub_assembly_node_id]
          a[:ancestor_id] = mapped_ancestor_id
          a[:node_template_id] = mapped_ancestor_id
        end
        ret
      end

      def get_matching_ports_link_hashes_in_target()
        ret = Array.new
        return ret unless @service_add_on
        port_links = @service_add_on.get_port_links()
        if port_links.empty?
          return ret
        end
        @service_add_on.update_object!(:sub_assembly_id)
        all_port_ids = port_links.map{|pl|[pl[:input_id],p[:output_id]]}.flatten
        targeted_node_ids = {:sub_assembly_id => @service_add_on[:sub_assembly_id],:assembly_id => base_assembly[:id]}
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:node_node_id,:anceestor_id],
          :filter => [:and,[:one_of, :anceestor_id, all_port_ids],[:one_of, :node_node_ids, targeted_node_ids.values]]
        }
        ndx_target_ports = Model.get_objs(model_handle(:port),sp_hash).inject(Hash.new) do |h,p|
          h.merge(p[:anceestor_id] => p)
        end
        port_links.each do |pl|
          if input_is_sub_assembly = pl[:output_is_local]
            in_assembly_id = targeted_node_ids[:sub_assembly_id]
            out_assembly_id = targeted_node_ids[:assembly_id]
          else
            out_assembly_id = targeted_node_ids[:sub_assembly_id]
            in_assembly_id = targeted_node_ids[:assembly_id]
          end
          
          target_in_port = ndx_target_port[pl[:input_id]]
          check_port(target_in_port,pl[:input_id],:input,in_assembly_id)
          target_out_port = ndx_target_port[pl[:output_id]]
          check_port(target_out_port,pl[:output_id],:output,out_assembly_id)

          ret << pl.hash_subset(:output_is_local,:required).mereg(:input_id => target_in_port[:id], :output_id => target_out_port[:id])
        end
        ret
      end
     private
      def check_port(target_port,port_id,dir,assembly_id)
        unless target_port
          Log.error("cannot find match for service add on port #{dir} input port with id (#{port_id})")
        end
        #TODO: also check to make sure that it tied to the right assembly as given by assembly_id
      end
    end
  end; end; end
end
    
