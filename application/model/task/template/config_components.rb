module DTK; class Task
  class Template
    class ConfigComponents < self
      r8_nested_require('config_components','persistence')

      def self.get_existing_or_stub_templates(action_types,assembly_instance)
        ret = Array.new
        #TODO: only returning now the task templates for the default (assembly create action)
        task_action = default_task_action()

        #getting content from Task::Template::ConfigComponents.get_or_generate and 
        #template object from assembly_instance.get_task_template of stub and spliciing in content 
        #with all but assembly actions filtered out

        opts = {:component_type_filter => :service, :task_action => task_action}
        unless task_template_content = get_or_generate_template_content(action_types,assembly_instance,opts)
          return ret
        end
        serialized_content = task_template_content.serialization_form(:filter => {:source => :assembly})
        
        default_action_task_template = assembly_instance.get_task_template(task_action,:cols => [:id,:group_id,:task_action])
        default_action_task_template ||= create_stub(assembly_instance.model_handle(:task_template),:task_action => task_action)
        ret << default_action_task_template.merge(:content => serialized_content)

        ret
      end

      #action_types can be 
      # :assembly
      # :node_centric
      def self.get_or_generate_template_content(action_types,assembly,opts={})
        action_types = Array(action_types)
        raise_error_if_unsupported_action_types(action_types)

        task_action = opts[:task_action]||default_task_action()
        action_list_opts = Aux.hash_subset(opts,[:component_type_filter])
        cmp_actions = ActionList::ConfigComponents.get(assembly,action_list_opts)

        #first see if there is a persistent serialized task template for assembly instance and that it should be used
        #get content from persisted 
        if assembly_action_content = Persistence::AssemblyActions.get_content_for(assembly,cmp_actions)
          ret = 
            if action_types == [:assembly]
              assembly_action_content
            else #action_types has both and assembly and node_centric
              node_centric_content = generate_from_temporal_contraints(:node_centric,assembly,cmp_actions)
              opts_splice = (node_centric_first_stage?() ? {:node_centric_first_stage => true} : Hash.new)
              assembly_action_content.splice_in_at_beginning!(node_centric_content,opts_splice)
            end
          return ret
        end

        #otherwise do the temporal processing to generate template_content
        opts_generate = (node_centric_first_stage?() ? {:node_centric_first_stage => true} : Hash.new)
        template_content = generate_from_temporal_contraints([:assembly,:node_centric],assembly,cmp_actions,opts_generate)

        unless opts[:dont_persist_generated_template]
          #persist assembly action part of what is generated
          Persistence::AssemblyActions.persist(assembly,template_content,task_action)
        end

        template_content
      end

     private
      def self.raise_error_if_unsupported_action_types(action_types)
        unless action_types.include?(:assembly)
          raise Error.new("Not supported when action types does not contain :assembly")
        end
        illegal_action_types = (action_types - [:assembly,:node_centric])
        unless illegal_action_types.empty?
          raise Error.new("Illegal action type(s) (#{illegal_action_types.join(',')})")
        end
      end
      def self.node_centric_first_stage?()
        true
      end

      def self.generate_from_temporal_contraints(action_types,assembly,cmp_actions,opts={})
        action_types =  Array(action_types)
        relevant_actions = 
          if action_types == [:assembly]
            cmp_actions.select{|a|a.source_type() == :assembly}
          elsif action_types == [:node_centric]
            cmp_actions.select{|a|a.source_type() == :node_group}
          else #action_types consists of :assembly nad :node_centric
            cmp_actions
          end
        temporal_constraints = TemporalConstraints::ConfigComponents.get(assembly,relevant_actions)
        Content.new(temporal_constraints,relevant_actions,opts)
      end
        
    end
  end
end; end
