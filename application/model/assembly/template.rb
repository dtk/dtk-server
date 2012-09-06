module DTK
  class AssemblyTemplate < Assembly
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
                      [:eq, :component_type, parts[0].gsub(/::/,"__")],
                      [:eq, :type, "composite"],
                      [:neq, :library_library_id, nil]]
          }
        elsif parts.size == 2
          {:cols => [:id,:component_type,:library],
           :filter => [:and,
                      [:eq, :component_type, parts[1].gsub(/::/,"__")],
                      [:eq, :type, "composite"]],
           :post_filter => lambda{|r|r[:library][:display_name] ==  parts[0]}
          }
      else
        raise ErrorNameInvalid.new(name,pp_object_type())
      end
      name_to_id_helper(model_handle,name,augmented_sp_hash)
    end
  end
end
