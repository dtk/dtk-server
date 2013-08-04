module DTK; class Task
  class Template < Model
    r8_nested_require('template','temporal_constraint')
    r8_nested_require('template','temporal_constraints')
    r8_nested_require('template','action_list')
    r8_nested_require('template','stages')

    class ConfigComponents < self
      def self.generate(assembly,component_type=nil)
        ret = create_stub(assembly.model_handle(:task_template))
        cmp_action_list = ActionList::ConfigComponents.get(assembly,component_type)
        temporal_constraints = TemporalConstraints::ConfigComponents.get(assembly,cmp_action_list)

        #internode_stages is of form [[2,3],[1],[4,5]]
        internode_stages = Stages.create_internode_stages(temporal_constraints,cmp_action_list)
        pp [:internode_stages,internode_stages.print_form()]
        ret
      end
    end
  end
end; end
