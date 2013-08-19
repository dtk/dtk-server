module DTK; class Task
  class Template < Model

    module ActionType
      Create = "__create_action"
    end

    module Serialization
      module Field
        Subtasks = :subtasks
        TemporalOrder = :subtask_order
        ExecutionBlocks = :exec_blocks
      end
      module Constant
        Concurrent = :concurrent
        Sequential = :sequential
      end
      class ParseError < ::DTK::ErrorUsage
      end

      #TODO: if support ruby 1.8.7 need to make this fn of a hash that perserves order 
      class OrderedHash < ::Hash
        def initialize(initial_val=nil)
          super()
          replace(initial_val) if initial_val
        end
      end
    end

    r8_nested_require('template','temporal_constraint')
    r8_nested_require('template','temporal_constraints')
    r8_nested_require('template','action')
    r8_nested_require('template','action_list')
    r8_nested_require('template','stage')
    r8_nested_require('template','content')
    r8_nested_require('template','config_components')

    def self.common_columns()
      [:id,:group_id,:display_name,:task_action,:content]
    end

    def self.default_task_action()
      ActionType::Create
    end

    def serialized_content_hash_form()
      if content = get_field?(:content)
        Serialization::OrderedHash.new(content)
      end
    end

    #returns [ref,create_hash]
    def self.ref_and_create_hash(serialized_content,task_action=nil)
      task_action ||= default_task_action()
      ref = ref(task_action)
      create_hash = {
        :task_action => task_action,
        :content => serialized_content
      }
      [ref,create_hash]
    end

   private
    def self.ref(task_action)
      task_action||default_task_action()
    end

    def self.persist_serialized_content(mh,serialized_content,match_assigns,task_action=nil)
      task_action ||= default_task_action()
      all_match_assigns = {:task_action => task_action}.merge(match_assigns)
      other_assigns = {:content => serialized_content}
      ref = ref(task_action)
      create_from_row?(mh,ref,all_match_assigns,other_assigns,:convert => true)
    end

  end
end; end
