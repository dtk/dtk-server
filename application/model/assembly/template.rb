module DTK
  class AssemblyTemplate < Assembly
    def self.name_to_id(model_handle,name)
      parts = name.split("/")
      post_filter = lambda{|r|true}
      if parts.size == 1
        sp_hash = {
          :cols => [:id,:component_type],
          :filter => [:and,
                      [:eq, :component_type, parts[0].gsub(/::/,"__")],
                      [:eq, :type, "composite"],
                      [:neq, :library_library_id, nil]]
        }
      elsif parts.size == 2
        sp_hash = {
          :cols => [:id,:component_type,:library],
          :filter => [:and,
                      [:eq, :component_type, parts[1].gsub(/::/,"__")],
                      [:eq, :type, "composite"]]
        }
        post_filter = lambda{|r|r[:library][:display_name] ==  parts[0]}
      else
        raise ErrorUsage.new("Illegal name for assembly template (#{name})")
      end
      rows = get_objs(model_handle,sp_hash).select{|r|post_filter.call(r)}
      if rows.size == 0
        raise ErrorUsage.new("Name (#{name}) for assembly template does not exist")
      elsif rows.size > 1
        raise ErrorUsage.new("Name (#{name}) does not unqiuely pick out a assembly template object")
      end
      rows.first[:id]
    end
  end
end
