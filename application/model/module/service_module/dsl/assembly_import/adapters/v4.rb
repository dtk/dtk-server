#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
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

        Target = 'target'
      end

      def self.assembly_iterate(service_module, hash_content, opts, &block)
        assembly_hash = (Constant.matches?(hash_content, :Assembly) || {}).merge(Constant.hash_subset(hash_content, AssemblyKeys))
        assembly_ref = service_module.assembly_ref(Constant.matches?(hash_content, :Name), opts[:module_version])
        assemblies_hash = { assembly_ref => assembly_hash }
        node_bindings_hash = Constant.matches?(hash_content, :NodeBindings)
        block.call(assemblies_hash, node_bindings_hash)
      end
      AssemblyKeys = [:Name, :Description, :Workflows, :Workflow, :Target]

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
            workflow_hash = r[:workflow] || {}
            # we explicitly want to delete from workflow_hash; workflow_action can be nil
            action_under_key = (workflow_hash.kind_of?(Hash) ? workflow_hash.delete(Constant::WorkflowAction) : nil)
            workflow_action = r[:action] || action_under_key
            parsed_workflow = parse_workflow(workflow_hash, workflow_action, assembly_hash, opts)
            h.merge(parsed_workflow)
          end
        end

        ret
      end

      def self.parse_workflow(workflow_hash, workflow_action, assembly_hash, opts = {})
        raise_error_if_parsing_error(workflow_hash, workflow_action, opts)
        check_if_invalid_component_in_workflow(assembly_hash, workflow_hash)

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
        if parse_error = Task::Template::ConfigComponents.find_parse_error?(workflow_hash, {workflow_action: workflow_action}.merge(opts))
          fail parse_error
        end
      end

      def self.check_if_invalid_component_in_workflow(assembly_hash, workflow_hash)
        workflow_components     = []
        all_assembly_components = []

        (workflow_hash['subtasks']||[]).each do |ws|
          if ordered_components = ws['ordered_components']
            workflow_components.concat(ordered_components) unless ordered_components.empty?
          end
        end

        if assembly_level_components = assembly_hash['components']
          parse_and_add_components(all_assembly_components, assembly_level_components)
        end

        (assembly_hash['nodes']||{}).each do |name, content|
          if content_components = content && content['components']
            parse_and_add_components(all_assembly_components, content_components)
          end
        end

        invalid_components = workflow_components.select{ |w_cmp| !all_assembly_components.include?(w_cmp) }
        unless invalid_components.empty?
          component = (invalid_components.size > 1) ? 'components' : 'component'
          is        = (invalid_components.size > 1) ? 'are' : 'is'
          fail ParsingError.new("The following #{component} (#{invalid_components.join(', ')}) that #{is} referenced in assembly workflow #{is} not specified among assembly level or node components and as such cannot be used in workflow.")
        end
      end

      def self.parse_and_add_components(all_assembly_components, components)
        # in specific cases only one component can be sent as components params
        components = [components] if components.is_a?(String)

        components.each do |component|
          if component.is_a?(Hash)
            name_without_title = component.keys.first
            cmp_name           = append_name_attribute?(component)

            # special case when using puppet definitions where name_attribute is not used as title
            unless cmp_name.eql?(name_without_title)
              all_assembly_components << name_without_title
            end

            all_assembly_components << cmp_name
          else
            all_assembly_components << component
          end
        end
      end

      def self.append_name_attribute?(component)
        cmp_name = component.keys.first
        value = component.values.first

        return cmp_name if cmp_name.include?('[') && cmp_name.include?(']')

        if attributes = value['attributes']
          if name = attributes['name']
            cmp_name = "#{cmp_name}[#{name}]"
          end
        end

        cmp_name
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