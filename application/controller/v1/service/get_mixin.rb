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
module DTK
  class V1::ServiceController
    module GetMixin
      ### For all services

      def list
        params_hash = params_hash(:detail_level, :include_namespaces).merge(remove_assembly_wide_node: true)
        rest_ok_response Assembly::Instance.list(model_handle, params_hash), datatype: :assembly
      end

      ### Service instance specific

      def actions
        type = request_params(:type)
        rest_ok_response assembly_instance.list_actions(type), datatype: :service_actions
      end

      def attributes
        # TODO: DTK-3173: temporarily took out node and component filtering until it is fixed up
        assembly_instance = assembly_instance()
        detail_to_include = []
        datatype          = :workspace_attribute
        opts              = Opts.new(detail_level: nil)
        # TODO: DTK-3173: removed code
        filter_component  = request_params(:filter_component)
        attribute_name    = request_params(:attribute_name)
        format            = request_params(:format) || 'table' # default format type is table
        all, links        = boolean_request_params(:all, :links)


        if links
          detail_to_include << :attribute_links
          datatype = :workspace_attribute_w_link
        end

        if filter_component
          opts.merge!(filter_component: filter_component)
        end

        unless attribute_name.empty?
          opts.merge!(attribute_name: attribute_name)
        end
        # TODO: DTK-3173: removed code
        # if node_id = request_params(:node_id)
        #  node_id = "#{ret_node_id(:node_id, assembly_instance)}" unless (node_id =~ /^[0-9]+$/)
        #  opts.merge!(node_cmp_name: true)
        # end

        # if component_id = request_params(:component_id)
        #  component_id = "#{ret_component_id(:component_id, assembly_instance, filter_by_node: true)}" unless (component_id =~ /^[0-9]+$/)
        #end
        additional_filter_proc = Proc.new do |e|
          attr = e[:attribute]
          (!attr.is_a?(Attribute)) || !attr.filter_when_listing?({})
        end

        #opts[:filter_proc] = Proc.new do |element|
        #  if element_matches?(element, [:node, :id], node_id) && element_matches?(element, [:attribute, :component_component_id], component_id)
        #    element if additional_filter_proc.nil? || additional_filter_proc.call(element)
        #  end
        #end
        # TODO: DTK-3173: replaced code
        opts[:filter_proc] = additional_filter_proc

        truncate = (format == 'table')
        opts.merge!(truncate_attribute_values: truncate, mark_unset_required: true)
        opts.merge!(detail_to_include: detail_to_include.map(&:to_sym)) unless detail_to_include.empty?
        # TODO: DTK-3173: removed code
        response = 
          if format == 'yaml'
            opts.merge!(:yaml_format => true)
            format_yaml_response(assembly_instance.list_attributes(opts))
          else
            assembly_instance.list_attributes(opts)
          end
        rest_ok_response response, datatype: datatype
      end

      # TODO: will subsume required_attributes by attributes
      def required_attributes
        # required_attrs = assembly_instance.get_attributes_print_form(Opts.new(filter: :required_unset_attributes))
        rest_ok_response assembly_instance.get_required_unset_attributes
      end

      def get_attribute
        name = request_params(:name)
        all_attributes = assembly_instance.list_attributes()
        if attribute = all_attributes.select {|attr| attr[:name].eql? name}.first
          rest_ok_response attribute[:value]
        else
          rest_ok_response
        end
      end

      def components
        datatype = :component
        opts = Opts.new(detail_level: nil)
        opts[:filter_proc] = Proc.new do |e|
          node = e[:node]
          (!node.is_a?(Node)) || !Node::TargetRef.is_target_ref?(node)
        end
        
        if request_params(:dependencies)
          opts.merge!(detail_to_include: [:component_dependencies])
          datatype = :component_with_dependencies
        end

        rest_ok_response assembly_instance.info_about(:components, opts), datatype: datatype
      end

      def component_links
        component_links = assembly_instance.list_component_links
        rest_ok_response component_links, datatype: :service_link
      end

      def dependent_modules
        rest_ok_response assembly_instance.list_dependent_modules, datatype: :assembly_component_module
      end

      def nodes
        rest_ok_response assembly_instance.info_about(:nodes), datatype: :node
      end

      def repo_info
        rest_ok_response service_instance.get_base_module_repo_info
      end

      def base_and_nested_repo_info
        rest_ok_response service_instance.get_base_and_nested_module_repo_info
      end

      def task_status
        form = request_params(:form)
        opts = {}
        if form == 'stream_form'
          element_detail = request_params(:element_detail)||{}
          element_detail[:action_results] ||= true
          element_detail[:errors] ||= true

          opts = {
            end_index:      request_params(:end_index),
            start_index:    request_params(:start_index),
            element_detail: element_detail
          }
          if wait_for = request_params(:wait_for)
            opts.merge!(wait_for: wait_for.to_sym)
          end
        end

        begin
          assembly_instance = assembly_instance()
        rescue ErrorNameDoesNotExist => e
          raise ErrorUsage.new("No tasks found for this assembly") unless task_id = request_params(:task_id)
          opts.merge!({ format: :table, task_id: task_id })
          return rest_ok_response Task::Status::SnapshotTaskStreamForm.get_status(get_default_project.id_handle, opts) if form == 'stream_form'
          return rest_ok_response Task::Status::SnapshotTask.get_status(get_default_project.id_handle, opts), datatype: :task_status
        end
        
        response =
          if form == 'stream_form'
            Task::Status::Assembly::StreamForm.get_status(assembly_instance.id_handle, opts)
          else
            Task::Status::Assembly.get_status(assembly_instance.id_handle, format: :table)
          end

        rest_ok_response response, datatype: :task_status
      end

      def violations
        violations = assembly_instance.find_violations
        rest_ok_response violations.table_form, datatype: :violation
      end

      def info
        rest_ok_response assembly_instance.info
      end

      def describe
        response = assembly_instance.describe(request_params(:path), request_params)
        if request_params(:show_steps)
          rest_ok_response response, datatype: :describe_action_show_steps
        else
          rest_ok_response response
        end
      end

    end
  end
end
