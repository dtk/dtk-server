module DTK; class Task
  class Template
    class ConfigComponents < self
      def self.get_or_generate(assembly,component_type=nil)
        if serialized_content = get_serialized_content_from_assembly(assembly)
pp [:persisted_serialized_content,serialized_content]
          unless need_to_recalculate_template?(assembly)
            return Template.reify(serialized_content)
          end
        end

        cmp_action_list = ActionList::ConfigComponents.get(assembly,component_type)
        temporal_constraints = TemporalConstraints::ConfigComponents.get(assembly,cmp_action_list)
        opts = {:internode_stage_name_proc => lambda{|x|generate_internode_stage_name(x)}}
        template_content = Content.new(temporal_constraints,cmp_action_list,opts)
        serialized_content = template_content.serialization_form()
        persist_serialized_content_on_assembly(assembly,serialized_content)
        template_content
      end

      def self.generate_internode_stage_name(internode_stage_index)
        "config_nodes_stage_#{internode_stage_index.to_s}"
      end
      
     private
      def self.get_serialized_content_from_assembly(assembly,task_action=nil)
        task_template_mh = assembly.model_handle(:task_template)
        filter = [:eq,:component_component_id,assembly.id()]
        Template.get_serialized_content(task_template_mh,filter,task_action)
      end

      def self.persist_serialized_content_on_assembly(assembly,serialized_content,task_action=nil)
        task_template_mh = assembly.model_handle(:model_name => :task_template,:parent_model_name => :assembly)
        match_assigns = {:component_component_id => assembly.id()}
        Template.persist_serialized_content(task_template_mh,serialized_content,match_assigns,task_action)
      end
        
      def self.need_to_recalculate_template?(assembly,task_action=nil)
        task_action ||= default_task_action()
        #TODO: stub
        true 
      end
    end
  end
end; end
