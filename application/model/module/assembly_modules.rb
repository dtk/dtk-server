module DTK
  class AssemblyModules
    def self.create_component_modules?(assembly,component_instances)
      return if exists_component_modules?(assembly,component_instances)
      pp [:create_component_modules,assembly.class,component_instances.map{|r|r.class},component_instances]
      cmp_template_idhs = component_instances.map{|r|r.id_handle(:id => r[:component_template_id])}
      cmp_tmpl_ndx_cmp_modules = Component::Template.get_indexed_component_modules(cmp_template_idhs)
      pp [:ndx_cmp_modules,cmp_tmpl_ndx_cmp_modules]
      ndx_cmp_modules = Hash.new
      cmp_tmpl_ndx_cmp_modules.each_value do |cmp_mod|
        ndx_cmp_modules[cmp_mod[:id]] ||= cmp_mod
      end
      pp [:cmp_modules,ndx_cmp_modules.values]
      #TODO: very expensive call; will refine
      module_version = ModuleVersion.create_for_assembly(assembly)
      ndx_cmp_modules.values.map do |cmp_module|
        opts = {:base_version=>cmp_module.get_field?(:version),:assembly_module=>true}
        cmp_module.create_new_version(module_version,opts)
      end
      nil
    end
   private
    def self.exists_component_modules?(assembly,component_instances)
      false #TODO: stub
    end
  end
end
