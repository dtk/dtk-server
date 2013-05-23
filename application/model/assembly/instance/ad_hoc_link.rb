module DTK
  class Assembly::Instance
   module AdHocLinkMixin
     def add_ad_hoc_service_link?(service_type,input_cmp_idh,output_cmp_idh)
       AdHocLink.new(self,service_type,input_cmp_idh,output_cmp_idh).add_service_link?()
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
     def add_service_link?()
       port_link = nil
       input_port,output_port,new_port_created = add_or_ret_ports?()
       unless new_port_created
         #see if there is an existing port link
         #TODO: may also add filter on service_type
         filter = [:and,[:eq,:input_id,input_port.id()],[:eq,:output_id,output_port.id()]]
         pl_matches = @assembly_instance.get_port_links(:filter => filter)
         if pl_matches.size == 1
           port_link =  pl_matches.first
         elsif pl_matches.size > 1
           raise Error.new("Unexpected result that matches more than one port link (#{pl_matches.inspect})")
         end
       end
       port_link ||= create_new_port_link(input_port,output_port)

       port_link && port_link.id_handle() 
     end
    private
     #returns input_port,output_port,new_port_created (boolean)
     def add_or_ret_ports?()
       new_port_created = false
       ndx_matching_ports = find_matching_ports?([@input_cmp_idh,@output_cmp_idh]).inject(Hash.new){|h,p|h.merge(p[:component_id] => p)} 
       unless input_port = ndx_matching_ports[@input_cmp_idh.get_id()] 
         input_port = create_port(:input)
         new_port_created = true
       end 
       unless output_port = ndx_matching_ports[@output_cmp_idh.get_id()] 
         output_port =  create_port(:output)
         new_port_created = true
       end
       [input_port,output_port,new_port_created]
     end

     def find_matching_ports?(cmp_idhs)
       sp_hash = {
         :cols => [:id,:group_id,:display_name,:component_id],
         :filter => [:oneof,:component_id,cmp_idhs.map{|idh|idh.get_id()}]
       }
       port_mh = cmp_idhs.first.createMH(:port)
       Model.get_objs(port_mh,sp_hash).select{|p|p.link_def_name() == @service_type}
     end

     def create_port(direction)
       @input_cmp.update_object!(:node_node_id,:component_type)
       @output_cmp.update_object!(:node_node_id,:component_type)
       link_def_stub = {:link_type => @service_type}
       if @input_cmp[:node_node_id] == @output_cmp[:node_node_id]
         link_def_stub[:has_internal_link] = true
       else
         link_def_stub[:has_external_link] = true
       end
       component = (direction == :input ? @input_cmp : @output_cmp)
       node = @assembly_instance.id_handle(:model_name => :node,:id => component[:node_node_id]).create_object()
       create_hash = Port.ret_port_create_hash(link_def_stub,node,component,:direction => direction.to_s)
       port_mh = node.child_model_handle(:port)
       new_port_idh = Model.create_from_rows(port_mh,[create_hash]).first
       new_port_idh.create_object()
     end

     def create_new_port_link(input_port,output_port)
       target_idh = @assembly_instance.id_handle().get_parent_id_handle_with_auth_info()
       hash_to_create = {
         :assembly_id => @assembly_instance.id(),
         :input_id => input_port.id(),
         :output_id => output_port.id()
       } 
       PortLink.create_from_hash(target_idh,hash_to_create)
     end

   end
  end
end
