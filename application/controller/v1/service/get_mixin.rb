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
        assembly_instance = assembly_instance()
        detail_to_include = []
        datatype          = :workspace_attribute
        opts              = Opts.new(detail_level: nil)
        filter_component  = request_params(:filter_component)
        
        # TODO: temporary set to true if and only if no component filter, until '--all' flag is being added
        # then wil be #boolean_request_params(:all) 
        all               = filter_component.nil?
        format            = request_params(:format)

        if request_params(:links)
          detail_to_include << :attribute_links
          datatype = :workspace_attribute_w_link
        end

        if node_id = request_params(:node_id)
          node_id = "#{ret_node_id(:node_id, assembly_instance)}" unless (node_id =~ /^[0-9]+$/)
          opts.merge!(node_cmp_name: true)
        end

        if component_id = request_params(:component_id)
          component_id = "#{ret_component_id(:component_id, assembly_instance, filter_by_node: true)}" unless (component_id =~ /^[0-9]+$/)
        end
        
        additional_filter_proc = Proc.new do |e|
          attr = e[:attribute]
          (!attr.is_a?(Attribute)) || !attr.filter_when_listing?({})
        end

        opts[:filter_proc] = Proc.new do |element|
          if element_matches?(element, [:node, :id], node_id) && element_matches?(element, [:attribute, :component_component_id], component_id)
            element if additional_filter_proc.nil? || additional_filter_proc.call(element)
          end
        end

        opts.merge!(truncate_attribute_values: !format.include?('yaml'), mark_unset_required: true)
        opts.merge!(detail_to_include: detail_to_include.map(&:to_sym)) unless detail_to_include.empty?
        opts.merge!(all: all, filter_component: filter_component)
        response = 
          if format.include?('yaml')
            opts.merge!(:yaml_format => true)
            format_yaml_response(assembly_instance.list_attributes(opts))
          else
            assembly_instance.list_attributes(opts)
          end
        rest_ok_response response, datatype: datatype
      end

      # TODO: will subsume required_attributes by attributes
      def required_attributes
        rest_ok_response assembly_instance.get_attributes_print_form(Opts.new(filter: :required_unset_attributes))
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
        rest_ok_response assembly_instance.list_component_links, datatype: :service_link
      end

      def dependent_modules
        rest_ok_response assembly_instance.info_about(:modules, Opts.new(detail_to_include: [:version_info])), datatype: :assembly_component_module
      end

      def nodes
        rest_ok_response assembly_instance.info_about(:nodes), datatype: :node
      end

      def repo_info
        rest_ok_response service_instance.get_repo_info
      end

      def task_status
        assembly_instance = assembly_instance()

        response =
          if request_params(:form) == 'stream_form'
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

    end
  end
end
