module DTK
  class Assembly::Instance
   module AdHocLinkMixin
     def add_ad_hoc_service_link(server_type,input_cmp_idh,output_cmp_idh)
       AdHocLink.new(self,service_type).add_service_link(input_cmp_idh,output_cmp_idh)
     end
   end
   
   class AdHocLink
     def initialize(assembly_instance,service_type)
       @assembly_instance = assembly_instance
       @service_type = service_type
     end
     def add_service_link(server_type,input_cmp_idh,output_cmp_idh)
       ndx_matching_ports = find_matching_ports?([input_cmp_idh,output_cmp_idh]).injec(Hash.new){|h,p|h.merge(p[:id] => p)} 
       input_port = ndx_matching_ports[input_cmp_idh.get_id()]
       output_port = ndx_matching_ports[output_cmp_idh.get_id()]
     end
    private
     def find_matching_ports?(cmp_idhs)
       ret = Array.new
       sp_hash = {
         :cols => Port.common_columns(),
         :filter => [:oneof,:compoennt_id,cmp_idhs.map{|idh|idh.get_id()}]
       }
       cmp_mh = cmp_idhs.first.createMH()
       ports = Model.get_obj(cmp_mh,sp_hash)
       return ret if ports.empty?()
       ports
     end
   end
  end
end
