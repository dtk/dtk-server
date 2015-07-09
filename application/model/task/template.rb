module DTK; class Task
  class Template < Model
    module ActionType
      Create = '__create_action'
    end

    module Serialization
      module Field
        Subtasks = :subtasks
        TemporalOrder = :subtask_order
        ExecutionBlocks = :exec_blocks
      end
      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin

        ComponentGroup = :Component_group

        Concurrent = :concurrent
        Sequential = :sequential
        OrderedComponents = :ordered_components
        Components = :components

        ## TODO: above are in old form

        Actions = 'actions'

        AllApplicable = 'All_applicable'
        Variations::AllApplicable = %w(All_applicable All All_Applicable AllApplicable)

        Node = 'node'
        Variations::Node = ['node','node_group']
        NodeGroup = 'node_group'

        Nodes = 'nodes'
        Variations::Nodes = ['nodes'] #TODO: dont think we need this because single variation

        Subtasks = 'subtasks'
      end

      # TODO: if support ruby 1.8.7 need to make this fn of a hash class that perserves order
      class OrderedHash < ::Hash
        def initialize(initial_val=nil)
          super()
          replace(initial_val) if initial_val
        end
      end
    end

    r8_nested_require('template','parsing_error')
    r8_nested_require('template','task_action_not_found_error')
    r8_nested_require('template','temporal_constraint')
    r8_nested_require('template','temporal_constraints')
    r8_nested_require('template','action')
    r8_nested_require('template','action_list')
    r8_nested_require('template','stage')
    r8_nested_require('template','content')
    r8_nested_require('template','config_components')
    r8_nested_require('template','task_params')

    def self.common_columns
      [:id,:group_id,:display_name,:task_action,:content]
    end

    def self.list_component_methods(project,assembly)
      ConfigComponents::ComponentAction.list(project,assembly)
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

      def get_task_actions(assembly)
        get_task_templates(assembly,cols: [:id,:group_id,:task_action])
      end

      def get_task_templates(assembly,opts={})
        sp_hash = {
          cols: opts[:cols]||common_columns(),
          filter: [:eq,:component_component_id,assembly.id()]
        }
        get_objs(assembly.model_handle(:task_template),sp_hash)
      end

      def get_task_template(assembly,task_action=nil,opts={})
        sp_hash = {
          cols: opts[:cols]||common_columns(),
          filter: [:and,[:eq,:component_component_id,assembly.id()],
                   [:eq,:task_action,internal_task_action(task_action)]]
        }
        get_obj(assembly.model_handle(:task_template),sp_hash)
      end

      private

      def internal_task_action(task_action=nil)
        ret = task_action
        if ret.nil? || ret == default_task_action_external_name()
          ret = default_task_action()
        end
        ret
      end
    end

    def serialized_content_hash_form(opts={})
      if hash_content = get_field?(:content)
        self.class.serialized_content_hash_form(hash_content,opts)
      end
    end

    def self.serialized_content_hash_form(hash,opts={})
      ret = Serialization::OrderedHash.new(hash)
      if task_params = opts[:task_params]
        ret = TaskParams.bind_task_params(ret,task_params)
      end
      ret
    end

    # returns [ref,create_hash]
    def self.ref_and_create_hash(serialized_content,task_action=nil)
      task_action ||= default_task_action()
      ref = ref(task_action)
      create_hash = {
        task_action: task_action,
        content: serialized_content
      }
      [ref,create_hash]
    end

    private

    def self.ref(task_action)
      task_action||default_task_action()
    end

    def self.create_or_update_from_serialized_content?(assembly_idh,serialized_content,task_action=nil)
      if task_template = get_matching_task_template?(assembly_idh,task_action)
        task_template.update(content: serialized_content)
        task_template.id_handle()
      else
        task_action ||= default_task_action()
        ref,create_hash = ref_and_create_hash(serialized_content,task_action)
        create_hash.merge!(ref: ref,component_component_id: assembly_idh.get_id())
        task_template_mh = assembly_idh.create_childMH(:task_template)
        create_from_row(task_template_mh,create_hash,convert: true)
      end
    end

    def self.delete_task_template?(assembly_idh,task_action=nil)
      if task_template = get_matching_task_template?(assembly_idh,task_action)
        task_template_idh = task_template.id_handle()
        delete_instance(task_template_idh)
        task_template_idh
      end
    end

    def self.get_matching_task_template?(assembly_idh,task_action=nil)
      task_action ||= default_task_action()
      sp_hash = {
        cols: [:id],
        filter: [:and,[:eq,:component_component_id,assembly_idh.get_id],
                 [:eq,:task_action,task_action]]
      }
      task_template_mh = assembly_idh.createMH(model_name: :task_template,parent_model_name: :assembly)
      get_obj(task_template_mh,sp_hash)
    end
  end
end; end
