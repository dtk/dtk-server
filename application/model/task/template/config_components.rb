module DTK; class Task
  class Template
    class ConfigComponents < self
      def self.get_or_generate(assembly,component_type=nil)
        if serialized_content = get_serialized_content_from_assembly(assembly,Template::ActionType::Create)
          Template.reify(serialized_content)
        else
          cmp_action_list = ActionList::ConfigComponents.get(assembly,component_type)
          temporal_constraints = TemporalConstraints::ConfigComponents.get(assembly,cmp_action_list)
          opts = {:internode_stage_name_proc => lambda{|x|generate_internode_stage_name(x)}}
          Content.new(temporal_constraints,cmp_action_list,opts)
        end
      end

      def self.generate_internode_stage_name(internode_stage_index)
        "config_nodes_stage_#{internode_stage_index.to_s}"
      end
      
     private
      def self.get_serialized_content_from_assembly(assembly,action_type)
        task_template_mh = assembly.model_handle(:task_template)
        filter = [:eq,:component_component_id,assembly.id()]
        Template.get_serialized_content(task_template_mh,action_type,filter)
      end
    end
  end
end; end
