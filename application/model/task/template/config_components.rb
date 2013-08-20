module DTK; class Task
  class Template
    class ConfigComponents < self
      r8_nested_require('config_components','persistence')

      def self.get_existing_or_stub_templates(assembly_instance)
        ret = Array.new
        #TODO: only returning now the task templates for the default (assembly create action)
        task_action = default_task_action()

        #getting content from Task::Template::ConfigComponents.get_or_generate and 
        #template object from assembly_instance.get_task_template of stub and spliciing in content 
        #with all but assembly actions filtered out

        opts = {:component_type_filter => :service, :task_action => task_action}
        unless task_template_content = get_or_generate_template_content(assembly_instance,opts)
          return ret
        end
        serialized_content = task_template_content.serialization_form(:filter => {:source => :assembly})
        
        default_action_task_template = assembly_instance.get_task_template(task_action,:cols => [:id,:group_id,:task_action])
        default_action_task_template ||= create_stub(assembly_instance.model_handle(:task_template),:task_action => task_action)
        ret << default_action_task_template.merge(:content => serialized_content)

        ret
      end

      def self.get_or_generate_template_content(assembly,opts={})
        task_action = opts[:task_action]||default_task_action()
        action_list_opts = Aux.hash_subset(opts,[:component_type_filter])
        cmp_actions = ActionList::ConfigComponents.get(assembly,action_list_opts)

        #first see if there is a persistent serialized task template for assembly instance and that it should be used
        #get content from persisted 
        if ret = Persistence.get_content_for(assembly,cmp_actions)
          return ret
        end

        #otherwise do the temporal processing to generate template_content
        opts = (node_centric_first_stage?() ? {:node_centric_first_stage => true} : Hash.new)
        template_content = generate_from_temporal_contraints(assembly,cmp_actions,opts)

        unless opts[:dont_persist_generated_template]
          #persist what is generated
          Persistence.assembly,template_content)
        end

        template_content
      end

     private
      def self.node_centric_first_stage?()
        true
      end

      def self.generate_from_temporal_contraints(assembly,cmp_actions,opts={})
        temporal_constraints = TemporalConstraints::ConfigComponents.get(assembly,cmp_actions)
        Content.new(temporal_constraints,cmp_actions,opts)
      end

        
    end
  end
end; end
