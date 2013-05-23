module DTK
  class Assembly::Instance
   module AdHocLinkMixin
     def add_ad_hoc_service_link(service_type,input_cmp_idh,output_cmp_idh)
       AdHocLink.new(self,service_type,input_cmp_idh,output_cmp_idh).add_service_link()
     end
   end
   
   class AdHocLink
     def initialize(assembly_instance,service_type,input_cmp_idh,output_cmp_idh)
       @assembly_instance = assembly_instance
       @service_type = service_type
       @input_cmp_idh = input_cmp_idh
       @output_cmp_idh = output_cmp_idh
       @input_cmp = input_cmp_idh.create_object()
       @output_cmp = output_cmp_idh.create_object()
     end
     def add_service_link()
       input_port,output_port = add_or_ret_ports?()
pp [input_port,output_port]
       @assembly_instance.id_handle() #TODO: stub
     end
    private
     #returns input_port,output_port
     def add_or_ret_ports?()
       ndx_matching_ports = find_matching_ports?([@input_cmp_idh,@output_cmp_idh]).inject(Hash.new){|h,p|h.merge(p[:id] => p)} 
       input_port = ndx_matching_ports[@input_cmp_idh.get_id()] || ret_port_create_hash(:input)
       output_port = ndx_matching_ports[@output_cmp_idh.get_id()] || ret_port_create_hash(:output)
       [input_port,output_port]
     end

     def find_matching_ports?(cmp_idhs)
       sp_hash = {
         :cols => Port.common_columns(),
         :filter => [:oneof,:component_id,cmp_idhs.map{|idh|idh.get_id()}]
       }
       cmp_mh = cmp_idhs.first.createMH()
       Model.get_objs(cmp_mh,sp_hash).select{|p|p.link_def_name() == @service_type}
     end

     def ret_port_create_hash(dir)
       @input_cmp.update_object!(:node_node_id)
       @output_cmp.update_object!(:node_node_id)
       link_def_stub = {:link_type => @service_type}
       if @input_cmp[:node_node_id] == @output_cmp[:node_node_id]
         link_def_stub[:has_internal_link] = true
       else
         link_def_stub[:has_external_link] = true
       end
       component = (dir == :input ? @input_cmp : @output_cmp)
       node = @assembly_instance.id_handle(:model_name => :node,:id => component[:node_node_id]).create_object()
       Port.ret_port_create_hash(link_def_stub,node,component)
     end

   end
  end
end
