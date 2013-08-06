module DTK; class Task
  class Template < Model
    r8_nested_require('template','temporal_constraint')
    r8_nested_require('template','temporal_constraints')
    r8_nested_require('template','action')
    r8_nested_require('template','action_list')
    r8_nested_require('template','stage')
    r8_nested_require('template','stages')

    class ConfigComponents < self
      #TODO: put in logic that looks at the assembly and sees if there is a an assembly template persisted with it
      #in which case it will reify the serialized content to for a stages object and return it here
      def self.get_or_generate_stages(assembly,component_type=nil)
        cmp_action_list = ActionList::ConfigComponents.get(assembly,component_type)
        temporal_constraints = TemporalConstraints::ConfigComponents.get(assembly,cmp_action_list)
        Stages::Internode.create_stages(temporal_constraints,cmp_action_list)
      end
    end
  end
end; end
