module DTK
  class AssemblyInstance < Assembly
    def info_about(about)
      cols = post_process = nil
      case 
       when :components 
        cols = [:components]
        post_process = proc{|r|r[:component2].hash_subset(:id,:display_name)}
      end
      unless cols
        raise Error.new("TODO: not implemented yet: processing of info_about(#{about})")
      end
      rows = get_objs(:cols => cols)
      post_process ? rows.map{|r|post_process.call(r)} : rows
    end

    def self.check_valid_id(model_handle,id)
      filter = 
        [:and,
         [:eq, :id, id],
         [:eq, :type, "composite"],
         [:neq, :datacenter_datacenter_id, nil]]
      check_valid_id_helper(model_handle,id,filter)
    end

    def self.name_to_id(model_handle,name)
      parts = name.split("/")
      augmented_sp_hash = 
        if parts.size == 1
          {:cols => [:id],
           :filter => [:and,
                      [:eq, :display_name, parts[0]],
                      [:eq, :type, "composite"],
                      [:neq, :datacenter_datacenter_id, nil]]
          }
        elsif parts.size == 2
          {:cols => [:id,:component_type,:target],
           :filter => [:and,
                      [:eq, :display_name, parts[1]],
                      [:eq, :type, "composite"]],
           :post_filter => lambda{|r|r[:target][:display_name] ==  parts[0]}
          }
      else
        raise ErrorNameInvalid.new(name,pp_object_type())
      end
      name_to_id_helper(model_handle,name,augmented_sp_hash)
    end
    #TODO: probably move to Assembly
    def model_handle()
      super(:component)
    end
  end
end

