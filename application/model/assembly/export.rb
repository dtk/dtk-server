#exports an assembly isnatnce or templaet in serialized form
module XYZ
  module AssemblyExportMixin
    def export(opts={})
      nested_objs = AssemblyExportInternal.get_nested_objects_for_export(self)
      assembly_hash = AssemblyExportInternal.assembly_output_hash(self,nested_objs)
      node_bindings_hash = AssemblyExportInternal.node_bindings_output_hash(nested_objs)
File.open("/tmp/t2","w"){|f| f << JSON.pretty_generate(nested_objs)}
out = SimpleOrderedHash.new([{:node_bindings => node_bindings_hash}, {:assemblies => {assembly_hash[:name] => assembly_hash}}])
File.open("/tmp/t3","w"){|f| f << JSON.pretty_generate(out)}
    end
   private
    module AssemblyExportInternal
      include AssemblyImportExportCommon
      def self.get_nested_objects_for_export(assembly)
        #get assembly level attributes
        sp_hash = {
          :cols => [:id,:display_name,:data_type,:value_asserted],
          :filter => [:eq, :component_component_id, assembly.id()]
        }
        assembly_attrs = Model.get_objs(assembly.model_handle(:attribute),sp_hash)

        #get nodes, components and implementations
        ndx_nodes = Hash.new
        ndx_impls = Hash.new
        ndx_node_bindings = Hash.new
        cmps = Array.new
        assembly_ref = assembly.update_object!(:ref)[:ref]
        sp_hash = {:cols => [:nested_nodes_and_cmps_for_export]}
        assembly.get_objs(sp_hash,:keep_ref_cols => true).each do |r|
          node = r[:node]
          node = ndx_nodes[node[:id]] ||= node.merge(:components => Array.new)
          ndx_node_bindings[node[:id]] ||= {:assembly_ref => assembly_ref,:node_display_name => node[:display_name], :node_binding_rs_ref => r[:node_binding_ruleset][:ref]}
          cmp = r[:nested_component]
          cmps << cmp
          node[:components] << cmp
          ndx_impls[cmp[:implementation_id]] ||= r[:implementation]
        end

        unless cmps.empty?
          #get non-default attributes on components
          sp_hash = {
            :cols => [:id,:component_component_id,:display_name,:attribute_value],
            :filter => [:and,[:eq,:is_instance_value,true],[:oneof,:component_component_id,cmps.map{|cmp|cmp[:id]}]]
          }
          non_default_attrs = Model.get_objs(assembly.model_handle(:attribute),sp_hash) 
          non_default_attrs.each do |attr|
            cmps.each do |cmp|
              if attr[:component_component_id] == cmp[:id]
                (cmp[:attributes] ||= Array.new) << attr
              end
            end
          end
        end

        #get ports
        nested_node_ids = ndx_nodes.keys
        sp_hash = {
          :cols => [:id,:display_name,:type,:direction,:node_node_id],
          :filter => [:oneof, :node_node_id, nested_node_ids]
        }
        ports = Model.get_objs(assembly.model_handle(:port),sp_hash)

        #get port links
        sp_hash = {
          :cols => PortLink.common_columns(),
          :filter => [:eq, :assembly_id, assembly.id()]
        }
        port_links = Model.get_objs(assembly.model_handle(:port_link),sp_hash)

        {:nodes => ndx_nodes.values, :ports => ports, :port_links => port_links, :attributes => assembly_attrs, :implementations => ndx_impls.values, :node_bindings => ndx_node_bindings.values}
      end

      def self.assembly_output_hash(assembly,nested_objs)
        ret = SimpleOrderedHash.new()
        ret[:name] = assembly.update_object!(:display_name)[:display_name]
        #add modules
        ret[:modules] = nested_objs[:implementations].map do |impl|
        #TODO: stub that ignores version = 1
          version = impl[:version_num]
          ((version.nil? or version == 1) ? impl[:module_name] : "#{impl[:module_name]}-#{version}") 
        end

        #add assembly level attributes
        #TODO: stub

        #add nodes and components
        ret[:nodes] = nested_objs[:nodes].inject(SimpleOrderedHash.new()) do |h,node|
          node_name = node[:display_name]
          cmp_info = node[:components].map{|cmp|component_output_form(cmp)}
          h.merge(node_name => {:components => cmp_info})
        end

        #add port links
        ndx_ports = nested_objs[:ports].inject(Hash.new){|h,p|h.merge(p[:id] => p)}
        ret[:port_links] = nested_objs[:port_links].map do |pl|
          input_port = ndx_ports[pl[:input_id]]
          output_port = ndx_ports[pl[:output_id]]
          {port_output_form(input_port,:input) => port_output_form(output_port,:output)}
        end
        ret
      end

      def self.component_output_form(component)
        name = component_name_output_form(component[:component_type])
        if component[:attributes]
          {name => component[:attributes].inject(Hash.new){|h,a|h.merge(a[:display_name] => a[:attribute_value])}}
        else
          name 
        end
      end

      def self.node_bindings_output_hash(nested_objs)
        nested_objs[:node_bindings].inject(Hash.new) do |h,nb|
          h.merge("#{nb[:assembly_ref]}#{Seperators[:assembly_node]}#{nb[:node_display_name]}" => nb[:node_binding_rs_ref])
        end
      end

      def self.port_output_form(port,dir)
        #example internal form component_external___hdp-hadoop__namenode___namenode_conn
        if port[:display_name] =~ /component_external___(.+)__(.+)___(.+$)/
          mod = $1;cmp = $2;port_name = $3
          "#{mod}#{Seperators[:module_component]}#{cmp}#{Seperators[:component_port]}#{port_name}"
        else
          ralse Error.new("unexpected display name #{port[:display_name]}")
        end
      end
   
      def self.component_name_output_form(internal_format)
        internal_format.gsub(/__/,Seperators[:module_component])
      end
    end
  end
end
