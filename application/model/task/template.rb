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
module DTK; class Task
  class Template < Model
    module ActionType
      Create = '__create_action'
    end

    # TODO: might not need to embed in Serialization
    module Serialization
      r8_nested_require('template', 'constant')
      module Field
        Subtasks = :subtasks
        TemporalOrder = :subtask_order
        ExecutionBlocks = :exec_blocks
      end
      # TODO: if support ruby 1.8.7 need to make this fn of a hash class that perserves order
      class OrderedHash < ::Hash
        def initialize(initial_val = nil)
          super()
          replace(initial_val) if initial_val
        end
      end
    end

    r8_nested_require('template', 'parsing_error')
    r8_nested_require('template', 'task_action_not_found_error')
    r8_nested_require('template', 'temporal_constraint')
    r8_nested_require('template', 'temporal_constraints')
    r8_nested_require('template', 'action')
    r8_nested_require('template', 'action_list')
    r8_nested_require('template', 'stage')
    r8_nested_require('template', 'content')
    r8_nested_require('template', 'config_components')
    r8_nested_require('template', 'task_params')

    def self.common_columns
      [:id, :group_id, :display_name, :task_action, :content]
    end

    def self.list_component_methods(project, assembly)
      ConfigComponents::ComponentAction.list(project, assembly)
    end

    class << self
      # internal name for default action
      def default_task_action
        ActionType::Create
      end

      def default_task_action_external_name
        DefaultTaskActionExternalName
      end
      DefaultTaskActionExternalName = 'create'

      def get_task_templates(assembly, opts = {})
        if opts[:serialized_form]
          get_task_templates_serialized_form(assembly, opts)
        else
          get_task_templates_simple_form(assembly, opts)
        end
      end

      def get_task_template(assembly, task_action, opts = {})
        sp_hash = {
          cols: opts[:cols] || common_columns(),
          filter: [:and, [:eq, :component_component_id, assembly.id()],
                   [:eq, :task_action, internal_task_action(task_action)]]
        }
        get_obj(assembly.model_handle(:task_template), sp_hash)
      end

      def get_serialized_content(assembly, task_action, opts = {})
        opts_task_gen = opts.merge(task_action: task_action)
        action_types = [:assembly]
        ret = ConfigComponents.get_or_generate_template_content(action_types, assembly, opts_task_gen)
        ret && ret.serialization_form(opts[:serialization_form] || {})
      end

      def task_action_external_name(task_action)
        (task_action.nil? or task_action == default_task_action) ? default_task_action_external_name : task_action
      end

      private

      def get_task_templates_simple_form(assembly, opts = {})
        sp_hash = {
          cols: opts[:cols] || common_columns(),
          filter: [:eq, :component_component_id, assembly.id()]
        }
        ret = get_objs(assembly.model_handle(:task_template), sp_hash)
        if opts[:set_display_names]
          ret.each {|task_t| task_t[:display_name] ||= task_action_external_name(task_t[:task_action]) }
        end
        ret
      end

      def get_task_templates_serialized_form(assembly, opts = {})
        ret = []

        opts_serialized_content = {
          component_type_filter: :service,
          serialization_form: { filter: { source: :assembly } }
        }.merge(opts)
        
        # TODO: more efficient if bulked these up
        get_task_templates_simple_form(assembly, cols: [:id, :task_action]).each do |task_template|
          task_action = task_template[:task_action]
          if serialized_content = get_serialized_content(assembly, task_action, opts_serialized_content)
            action_task_template = get_task_template(assembly, task_action, cols: [:id, :group_id, :task_action])
            action_task_template ||= Assembly::Instance.create_stub(assembly.model_handle(:task_template))
            ret << action_task_template.merge(content: serialized_content)
          end
        end
        ret
      end

      def internal_task_action(task_action = nil)
        ret = task_action
        if ret.nil? || ret == default_task_action_external_name()
          ret = default_task_action()
        end
        ret
      end
    end

    def serialized_content_hash_form(opts = {})
      if hash_content = get_field?(:content)
        self.class.serialized_content_hash_form(hash_content, opts)
      end
    end

    # opts can have keys:
    #   :task_params
    def self.serialized_content_hash_form(hash, opts = {})
      ret = Serialization::OrderedHash.new(hash)
      if task_params = opts[:task_params]
        ret = TaskParams.bind_task_params(ret, task_params)
      end
      ret
    end

    def self.clone_to_assembly(assembly, task_templates)
      assembly_id = assembly.id
      rows_to_add = task_templates.map do |t|
        ref, create_hash = ref_and_create_hash(t[:content], t[:task_action])
        create_hash.merge(:ref => ref, :component_component_id => assembly_id)
      end
      task_template_mh = assembly.model_handle(:task_template).merge(parent_model_name: :assembly_instance)
      create_from_rows(task_template_mh, rows_to_add, convert: true)
    end

    # returns [ref, create_hash]
    def self.ref_and_create_hash(serialized_content, task_action = nil)
      task_action ||= default_task_action()
      ref = ref(task_action)
      create_hash = {
        task_action: task_action,
        content: serialized_content
      }
      [ref, create_hash]
    end

    private

    def self.ref(task_action)
      task_action || default_task_action
    end

    def self.create_or_update_from_serialized_content?(assembly_idh, serialized_content, task_action = nil)
      update_from_serialized_content?(assembly_idh, serialized_content, task_action) ||
        create_from_serialized_content(assembly_idh, serialized_content, task_action)
    end

    def self.update_from_serialized_content(assembly_idh, serialized_content, task_action = nil)
      update_from_serialized_content?(assembly_idh, serialized_content, task_action) || fail(Error, "Unexpected that pdate_from_serialized_content? is nil")
    end

    def self.update_from_serialized_content?(assembly_idh, serialized_content, task_action = nil)
      if task_template = get_matching_task_template?(assembly_idh, task_action)
        task_template.update(content: serialized_content)
        task_template.id_handle
      end
    end

    def self.create_from_serialized_content(assembly_idh, serialized_content, task_action = nil)
      task_action ||= default_task_action
      ref, create_hash = ref_and_create_hash(serialized_content, task_action)
      create_hash.merge!(ref: ref, component_component_id: assembly_idh.get_id)
      task_template_mh = assembly_idh.create_childMH(:task_template)
      create_from_row(task_template_mh, create_hash, convert: true)
    end

    # def self.create_from_service_module(assembly_idh, serialized_content, task_action, ancestor_id)
    #   return if get_matching_task_template?(assembly_idh, task_action)
    #   ref, create_hash = ref_and_create_hash(serialized_content, task_action)
    #   create_hash.merge!(ref: ref, component_component_id: assembly_idh.get_id(), ancestor_id: ancestor_id)
    #   task_template_mh = assembly_idh.create_childMH(:task_template)
    #   create_from_row(task_template_mh, create_hash, convert: true)
    # end

    def self.delete_task_template?(assembly_idh, task_action = nil)
      if task_template = get_matching_task_template?(assembly_idh, task_action)
        task_template_idh = task_template.id_handle()
        delete_instance(task_template_idh)
        task_template_idh
      end
    end

    def self.get_matching_task_template?(assembly_idh, task_action = nil)
      task_action ||= default_task_action()
      sp_hash = {
        cols: [:id],
        filter: [:and, [:eq, :component_component_id, assembly_idh.get_id],
                 [:eq, :task_action, task_action]]
      }
      task_template_mh = assembly_idh.createMH(model_name: :task_template, parent_model_name: :assembly)
      get_obj(task_template_mh, sp_hash)
    end
  end
end; end
