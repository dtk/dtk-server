module DTK; class AssemblyModule
  class Component
    class Attribute < self
      def self.update(assembly,attribute_patterns)
        attribute_patterns.map{|ap|update_aux(assembly,ap)}
      end

     private
      def self.update_aux(assembly,attribute_pattern)
        cmp_template = attribute_pattern.component_instance().get_component_template_parent()
        component_module = cmp_template.get_component_module()
#        module_branch = create_assembly_branch?(assembly,component_module,:ret_module_branch=>true)
#TODO: stub 
        pp ["in #{self}"]
      end
    end
  end
end;end

