module DTK; class Task
  class Template < Model
    r8_nested_require('template','temporal_constraint')
    r8_nested_require('template','temporal_constraints')
    r8_nested_require('template','action_list')

    class ConfigComponents < self
      def self.generate(assembly,component_type=nil)
        ret = create_stub(assembly.model_handle(:task_template))
        cmp_action_list = ActionList::ConfigComponents.get(assembly,component_type)
        temporal_constraints = TemporalConstraints::ConfigComponents.get(assembly,cmp_action_list)
        pp [:temporal_constraints,temporal_constraints]
        #stage indexes is of form [[2,3],[1],[4,5]]
        indexes_in_stages = temporal_constraints.indexes_in_stages(cmp_action_list)
        pp [:indexes_in_stages,indexes_in_stages]
        ret
      end
    end
  end
end; end
