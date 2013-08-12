module DTK; class Task
  class Template
    class ConfigComponents < self
      def self.get_or_generate(assembly,component_type=nil)
        #first see if cached content
        if template_content = get_cached_template_content?(assembly)
          return template_content
        end

        #next see if there is a persistent serialized task template
        #TODO: modify to handle case where serialized_content is just assembly actions vs assembly plus node-centric actions
        #in former case want to splice in node centric
        if serialized_content = get_serialized_content_from_assembly(assembly)
          cmp_action_list = ActionList::ConfigComponents.get(assembly,component_type)
          return Content.parse_and_reify(serialized_content,cmp_action_list)
        end

        #otherwise do the temporal processing to generate template_content
        cmp_action_list = ActionList::ConfigComponents.get(assembly,component_type)
        temporal_constraints = TemporalConstraints::ConfigComponents.get(assembly,cmp_action_list)
        opts = {:internode_stage_name_proc => lambda{|x|generate_internode_stage_name(x)}}
        template_content = Content.new(temporal_constraints,cmp_action_list,opts)

        #persist serialized form
        serialized_content = template_content.serialization_form()
        persist_serialized_content_on_assembly(assembly,serialized_content)
        template_content
      end

      def self.generate_internode_stage_name(internode_stage_index)
        "config_nodes_stage_#{internode_stage_index.to_s}"
      end
      
     private
      def self.get_serialized_content_from_assembly(assembly,task_action=nil)
        ret = assembly.get_task_template(task_action)
        ret && ret.serialized_content_hash_form()
      end

      def self.persist_serialized_content_on_assembly(assembly,serialized_content,task_action=nil)
        task_template_mh = assembly.model_handle(:model_name => :task_template,:parent_model_name => :assembly)
        match_assigns = {:component_component_id => assembly.id()}
        Template.persist_serialized_content(task_template_mh,serialized_content,match_assigns,task_action)
      end
        
      def self.get_cached_template_content?(assembly,task_action=nil)
        task_action ||= default_task_action()
        #TODO: stub
        nil
      end
    end
  end
end; end
