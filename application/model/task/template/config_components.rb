module DTK; class Task
  class Template
    class ConfigComponents < self
      def self.get_or_generate(assembly,component_type=nil)
        #first see if cached content
        if template_content = get_cached_template_content?(assembly)
          return template_content
        end

        cmp_actions = ActionList::ConfigComponents.get(assembly,component_type)

        #next see if there is a persistent serialized task template
        if serialized_content = get_serialized_content_from_assembly(assembly)
          return Content.parse_and_reify(serialized_content,cmp_actions)
        end

        #next see if the assembly template that the assembly instance came from has a serialized task template
        #otherwise do the temporal processing to generate template_content
        template_content = 
          if serialized_content = get_serialized_content_from_assembly_template(assembly)
            assembly_content = Content.parse_and_reify(serialized_content,cmp_actions)
            node_centric_cmp_actions = ActionList.new(cmp_actions.select{|a|a.source_type() == :node_group})
            if node_centric_cmp_actions.empty?
              assembly_content
            else
              node_centric_content = generate_from_temporal_contraints(assembly,node_centric_cmp_actions)
              assembly_content.combine(node_centric_content)
            end
          else
            generate_from_temporal_contraints(assembly,cmp_actions)
          end

        #persist serialized form  on assembly instance
        serialized_content = template_content.serialization_form()
        persist_serialized_content_on_assembly(assembly,serialized_content)
        template_content
      end

      def self.generate_internode_stage_name(internode_stage_index)
        "config_nodes_stage_#{internode_stage_index.to_s}"
      end
      
     private
      def self.generate_from_temporal_contraints(assembly,cmp_actions)
        temporal_constraints = TemporalConstraints::ConfigComponents.get(assembly,cmp_actions)
        opts = {:internode_stage_name_proc => lambda{|x|generate_internode_stage_name(x)}}
        Content.new(temporal_constraints,cmp_actions,opts)
      end

      def self.get_serialized_content_from_assembly(assembly,task_action=nil)
        ret = assembly.get_task_template(task_action)
        ret && ret.serialized_content_hash_form()
      end

      def self.get_serialized_content_from_assembly_template(assembly,task_action=nil)
        ret = assembly.get_parents_task_template(task_action)
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
