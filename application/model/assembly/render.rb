#renders an asembly isnatnce or templaet in serialized form
module XYZ
  module AssemblyRender
    def render(opts={})
      nested_objs = get_nested_objects_for_render()
      output_hash = output_hash_form(nested_objs)
File.open("/tmp/t2","w"){|f| f << JSON.pretty_generate(nested_objs)}
node_binding_rs = debug_node_binding_rs()
out = SimpleOrderedHash.new([{:node_binding_rulesets => node_binding_rs}, {:assemblies => {output_hash[:name] => output_hash}}])
File.open("/tmp/t3","w"){|f| f << JSON.pretty_generate(out)}
File.open("/tmp/t4","w"){|f| f << PP.pp(node_binding_rs,f)}
    end

def debug_node_binding_rs()
  sp_hash = {
    :cols => [:id,:display_name,:external_ref],
    :filter => [:and, [:eq, :assembly_id, nil],[:neq, :library_library_id, nil]]
  }
  node_templates = Model.get_objs(model_handle(:node),sp_hash)
  node_templates.inject(SimpleOrderedHash.new) do |h,node|
    external_ref = debug_node_external_ref(node)
    rule = SimpleOrderedHash.new([{:conditions => Aux::hash_subset(external_ref,[:type,:region])},{:node_template => external_ref}])
    node_ref = node[:display_name].downcase.gsub(/ /,"-")

    h.merge(node_ref => SimpleOrderedHash.new([{:type => "clone"},{:rules => [rule]}]))
  end
end
def debug_node_external_ref(node)
  node_info =  SimpleOrderedHash.new
  external_ref = node[:external_ref]
  if external_ref[:type] == "ec2_image"
    ec2_fields = [:image_id,:size,:region,:availability_zone,:security_group_set]
    
    output = ([:type]+ec2_fields).map do |f|
      val = external_ref[f]||(f == :region ? "us-east-1" : nil) 
      {f => val} if val
    end.compact
    SimpleOrderedHash.new(output)
  else
    raise Error.new("Have not implemented support for node type #{external_ref[:type]}")
  end
end

   private
    def get_nested_objects_for_render()
      #get assembly level attributes
      sp_hash = {
        :cols => [:id,:display_name,:data_type,:value_asserted],
        :filter => [:eq, :component_component_id, id()]
      }
      assembly_attrs = Model.get_objs(model_handle(:attribute),sp_hash)

      #get nodes, components and implementations
      ndx_nodes = Hash.new
      ndx_impls = Hash.new
      sp_hash = {:cols => [:nested_nodes_and_cmps_for_render]}
      get_objs(sp_hash).each do |r|
        node = r[:node]
        node = ndx_nodes[node[:id]] ||= node.merge(:components => Array.new)
        cmp = r[:nested_component]
        node[:components] << cmp
        ndx_impls[cmp[:implementation_id]] ||= r[:implementation]
      end

      #get ports
      nested_node_ids = ndx_nodes.keys
      sp_hash = {
        :cols => [:id,:display_name,:type,:direction,:node_node_id],
        :filter => [:oneof, :node_node_id, nested_node_ids]
      }
      ports = Model.get_objs(model_handle(:port),sp_hash)

      #get port links
      sp_hash = {
        :cols => PortLink.common_columns(),
        :filter => [:eq, :assembly_id, id()]
      }
      port_links = Model.get_objs(model_handle(:port_link),sp_hash)

      {:nodes => ndx_nodes.values, :ports => ports, :port_links => port_links, :attributes => assembly_attrs, :implementations => ndx_impls.values}
    end

    def output_hash_form(nested_objs)
      ret = SimpleOrderedHash.new()
      ret[:name] = update_object!(:display_name)[:display_name]
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
        cmp_info = node[:components].map{|cmp|component_name_output_form(cmp[:component_type])}
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

    def port_output_form(port,dir)
      #example internal form component_external___hdp-hadoop__namenode___namenode_conn
      if port[:display_name] =~ /component_external___(.+)__(.+)___(.+$)/
        mod = $1;cmp = $2;port_name = $3
       ret = "#{mod}#{Module_seperator}#{cmp}#{Module_seperator}#{port_name}"
       ((dir == :input) ? "#{ret}_ref" : ret)
      else
        ralse Error.new("unexpected display name #{port[:display_name]}")
      end
    end
   
    def component_name_output_form(internal_format)
      internal_format.gsub(/__/,Module_seperator)
    end
    
    Module_seperator = "::"
  end
end
