module DTK
  class AssemblyTemplate < Assembly
    def self.list(assembly_mh,opts={})
      list_from_library(assembly_mh,opts)
    end
                  
    def info_about(about)
      cols = post_process = nil
      order = proc{|a,b|a[:display_name] <=> b[:display_name]}
      case about 
       when :components
        cols = [:template_nodes_and_cmps_summary]
        post_process = proc do |r|
          display_name = "#{r[:node][:display_name]}/#{pp_display_name(r[:nested_component][:display_name])}"
          r[:nested_component].hash_subset(:id).merge(:display_name => display_name)
        end
       when :nodes
        cols = [:node_templates]
        post_process = proc do |r|
          binding = r[:node_binding]
          binding_fields = binding.hash_subset(:os_type,{:display_name => :template_name})
          common_fields = binding.ret_common_fields_or_that_varies()
          {:type=>"ec2_image", :image_id=>:varies, :region=>:varies, :size=>"m1.medium"}
          common_fields_to_add = Aux::hash_subset(common_fields,[{:type => :template_type},:image_id,:size,:region]).reject{|k,v|v == :varies}
          binding_fields.merge!(common_fields_to_add)
          r[:node].hash_subset(:id,:display_name).merge(binding_fields)
        end
      end
      unless cols
        raise Error.new("TODO: not implemented yet: processing of info_about(#{about})")
      end

      rows = get_objs(:cols => cols)
      ret = post_process ? rows.map{|r|post_process.call(r)} : rows
      order ? ret.sort(&order) : ret
    end

    def self.exists?(library_idh,service_module_name,template_name)
      component_type = component_type(service_module_name,template_name)
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :component_type, component_type], [:eq, :library_library_id, library_idh.get_id()]]
      }
      get_obj(library_idh.createMH(:component),sp_hash)
    end

    def self.check_valid_id(model_handle,id)
      filter =
        [:and,
         [:eq, :id, id],
         [:eq, :type, "composite"],
         [:neq, :library_library_id, nil]]
      check_valid_id_helper(model_handle,id,filter)
    end

    def self.name_to_id(model_handle,name)
      parts = name.split("/")
      augmented_sp_hash = 
        if parts.size == 1
          {:cols => [:id,:component_type],
           :filter => [:and,
                      [:eq, :component_type, pp_name_to_component_type(parts[0])],
                      [:eq, :type, "composite"],
                      [:neq, :library_library_id, nil]]
          }
        elsif parts.size == 2
          {:cols => [:id,:component_type,:library],
           :filter => [:and,
                      [:eq, :component_type, pp_name_to_component_type(parts[1])],
                      [:eq, :type, "composite"]],
           :post_filter => lambda{|r|r[:library][:display_name] ==  parts[0]}
          }
      else
        raise ErrorNameInvalid.new(name,pp_object_type())
      end
      name_to_id_helper(model_handle,name,augmented_sp_hash)
    end

     #returns [service_module_name,assembly_name]
    def self.parse_component_type(component_type)
      component_type.split(ModuleTemplateSep)
    end
   private
    def pp_display_name(display_name)
      display_name.gsub(Regexp.new(ModuleTemplateSep),"::")
    end
    def self.pp_name_to_component_type(pp_name)
      pp_name.gsub(/::/,ModuleTemplateSep)
    end
     def self.component_type(service_module_name,template_name)
       "#{service_module_name}#{ModuleTemplateSep}#{template_name}"
     end

    ModuleTemplateSep = "__"

    #TODO: probably move to Assembly
    def model_handle()
      super(:component)
    end
  end
end
