module DTK; class ServiceModule
  class AssemblyImport
    r8_require('v3')
    class V4 < V3
      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin

        Name = 'name'

        Assembly = 'assembly'

        Description = 'description'

        NodeBindings = 'node_bindings'

        WorkflowAction = 'workflow_action'
        Variations::WorkflowAction = ['workflow_action', 'assembly_action']

        CreateWorkflowAction = 'create'

        Workflows = 'workflows'
        Workflow = 'workflow'
      end

      def self.assembly_iterate(service_module, hash_content, &block)
        assembly_hash = (Constant.matches?(hash_content, :Assembly) || {}).merge(Constant.hash_subset(hash_content, AssemblyKeys))
        assembly_ref = service_module.assembly_ref(Constant.matches?(hash_content, :Name))
        assemblies_hash = { assembly_ref => assembly_hash }
        node_bindings_hash = Constant.matches?(hash_content, :NodeBindings)
        block.call(assemblies_hash, node_bindings_hash)
      end
      AssemblyKeys = [:Name, :Description, :Workflows, :Workflow]

      def self.parse_node_bindings_hash!(node_bindings_hash, opts = {})
        if hash = NodeBindings::DSL.parse!(node_bindings_hash, opts)
          DBUpdateHash.new(hash)
        end
      end

      private

      def self.import_task_templates(assembly_hash, opts = {})
        ret = DBUpdateHash.new()
        workflows_to_parse =
          if workflow = Constant.matches?(assembly_hash, :Workflow)
            [{ workflow: workflow }]
          elsif workflows = Constant.matches?(assembly_hash, :Workflows)
            if workflows.is_a?(Hash)
              workflows.map { |(action, workflow)| { workflow: workflow, action: action } }
            elsif workflows.is_a?(Array)
              workflows.map { |workflow| { workflow: workflow } }
            end
          end

        if workflows_to_parse
          ret = workflows_to_parse.inject(ret) do  |h, r| 
            workflow_hash = r[:workflow]
            # we explicitly want to delete from workflow_hash; workflow_action can be nil
            action_under_key = (workflow_hash.kind_of?(Hash) ? workflow_hash.delete(Constant::WorkflowAction) : nil)
            workflow_action = r[:action] || action_under_key
            parsed_workflow = parse_workflow(workflow_hash, workflow_action, opts)
            h.merge(parsed_workflow)
          end
        end

        ret
      end

      def self.parse_workflow(workflow_hash, workflow_action, opts = {})
        raise_error_if_parsing_error(workflow_hash, workflow_action, opts)
        
        normalized_workflow_action = 
          if opts[:service_module_workflow]
            normalized_service_module_action(workflow_hash, workflow_action)
          else
            normalized_assembly_action(workflow_action)
          end

        task_template_ref = normalized_workflow_action
        task_template = {
          'task_action' => normalized_workflow_action,
          'content'     => workflow_hash
        }
        { task_template_ref => task_template }
      end

      def self.import_component_attribute_info(cmp_ref, cmp_input)
        super
        ret_input_attribute_info(cmp_input).each_pair do |attr_name, attr_info|
          if base_tags = attr_info['tags'] || ([attr_info['tag']] if attr_info['tag'])
            add_attribute_tags(cmp_ref, attr_name, base_tags)
          end
        end
      end

      def self.raise_error_if_parsing_error(workflow_hash, workflow_action, opts = {})
        if parse_errors = Task::Template::ConfigComponents.find_parse_error?(workflow_hash, {workflow_action: workflow_action}.merge(opts))
          fail parse_errors
        end
      end

      def self.normalized_service_module_action(workflow_hash, workflow_action)
        workflow_action || workflow_hash['name']
      end

      def self.normalized_assembly_action(workflow_action)
        if workflow_action.nil? or Constant.matches?(workflow_action, :CreateWorkflowAction)
          Task::Template.default_task_action()
        else
          workflow_action
        end
      end

      def self.ret_input_attribute_info(cmp_input)
        ret_component_hash(cmp_input)['attribute_info'] || {}
      end
      def self.add_attribute_tags(cmp_ref, attr_name, tags)
        attr_info = output_component_attribute_info(cmp_ref)
        (attr_info[attr_name] ||= { display_name: attr_name }).merge!(tags: HierarchicalTags.new(tags))
      end
    end
  end
end; end
