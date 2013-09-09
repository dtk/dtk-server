module DTK
  class AssemblyModules
    def self.create_component_modules(assembly,component_instances)
      pp [:create_component_modules,assembly.class,component_instances.map{|r|r.class},component_instances]
      cmp_template_idhs = component_instances.map{|r|r.id_handle(:id => r[:component_template_id])}
      cmp_tmpl_ndx_component_modules = Component::Template.get_indexed_component_modules(cmp_template_idhs)
      pp [:ndx_component_modules,cmp_tmpl_ndx_component_modules]
      ndx_component_modules = Hash.new
      cmp_tmpl_ndx_component_modules.each_value do |cmp_mod|
        ndx_component_modules[cmp_mod[:id]] ||= cmp_mod
      end
      pp [:component_modules,ndx_component_modules.values]
      #TODO: now call ComponentModule#create_new_version(<new version for assembly>) for component module
      nil
    end
  end
end
