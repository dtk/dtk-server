module DTK
  class Assembly::Instance
   module AdHocLinkMixin
     def add_ad_hoc_service_link(service_type,input_cmp_idh,output_cmp_idh)
       AdHocLink.new(self,service_type).add_service_link(input_cmp_idh,output_cmp_idh)
     end
   end
   
   class AdHocLink
     def initialize(assembly_instance,service_type)
       @assembly_instance = assembly_instance
       @service_type = service_type
     end
     def add_service_link(input_cmp_idh,output_cmp_idh)
       ndx_matching_ports = find_matching_ports?([input_cmp_idh,output_cmp_idh]).inject(Hash.new){|h,p|h.merge(p[:id] => p)} 
       input_port = ndx_matching_ports[input_cmp_idh.get_id()]
       output_port = ndx_matching_ports[output_cmp_idh.get_id()]
       @assembly_instance.id_handle() #TODO: stub
     end
    private
     def find_matching_ports?(cmp_idhs)
       sp_hash = {
         :cols => Port.common_columns(),
         :filter => [:oneof,:component_id,cmp_idhs.map{|idh|idh.get_id()}]
       }
       cmp_mh = cmp_idhs.first.createMH()
       Model.get_objs(cmp_mh,sp_hash).select{|p|p.link_def_name() == @service_type}
     end
   end
  end
end
