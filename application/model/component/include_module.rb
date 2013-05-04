module DTK; class Component
  class IncludeModule < Model
    def self.get_version_context(component_idhs,impl_idhs)
      include_modules = get_from_component_idhs(component_idhs)
      impl_info = get_impl_info(impl_idhs)
        ret = Array.new # using more complicated form rather than straight map becase want it to be a strict array, not DTK array
        impl_info.each do |impl|
          ret << {:repo => impl[:repo],:branch => impl[:branch], :implementation => impl[:module_name]}
        end
      ret
    end

   private
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

    def self.get_impl_info(impl_idhs)
      ret = Array.new
      return ret if impl_idhs.empty?
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:repo,:branch,:module_name,:version],
        :filter => [:oneof,:id,impl_ids]
      }
      impl_mh = impl_idhs.first.createMH()
      get_objs(impl_mh,sp_hash)
    end

  end
end; end
