module DTK; class Component
  class IncludeModule < Model
    def self.get_from_component_idhs(component_idhs)
      ret = Array.new()
      return ret if component_idhs.empty?
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:module,:version_constraint],
        :filter => [:oneof,:component_id,component_idhs.map{|idh|idh.get_id()}]
      }
      incl_mod_idh = component_idhs.first.createMH(:include_module)
      get_objs(incl_mod_idh,sp_hash)
    end

  end
end; end
