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
        OrderedComponents = :ordered_components
        Components = :components
        ComponentGroup = :Component_group
        # convert above to below form 
        module Variations
        end
        AllApplicable = 'All_applicable'
        Variations::AllApplicable = ['All_applicable','All','All_Applicable','AllApplicable']
        
        Node = 'node'
        Variations::Node = ['node','node_group']
        Nodes = 'nodes'
        Variations::Nodes = ['nodes']


        def self.its_legal_values(constant)
          single_or_set = variations(constant)
          if single_or_set.kind_of?(Array)
            "its legal values are: #{single_or_set.join(',')}"
          else
            "its legal value is: #{single_or_set}"
          end
        end

        def self.matches?(object,constant)
          unless object.nil?
            variations = variations(constant)
            if object.kind_of?(Hash)
              hash_matches_key?(object,variations)
            elsif object.kind_of?(String) or object.kind_of?(Symbol)
               variations.include?(object.to_s)
            else
              raise Error.new("Unexpected object class (#{object.class})")
            end            
          end
        end

       private            
        def self.variations(constant)
          begin
            variations = Variations.const_get(constant.to_s)
            variations.map{|v|v.to_s} + variations.map{|v|v.to_sym}
           rescue
            # if Variations not defined
            term = const_get(constant.to_s)
            [term.to_s,term.to_sym]
          end
        end

        def self.hash_matches_key?(hash,variations)
          if match_key = variations.find{|key|hash.has_key?(key)}
            hash[match_key]
          end
        end
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
      if hash_content = get_field?(:content)
        self.class.serialized_content_hash_form(hash_content)
      end
    end

    def self.serialized_content_hash_form(hash)
      Serialization::OrderedHash.new(hash)
    end

    # returns [ref,create_hash]
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

    def self.create_or_update_from_serialized_content?(assembly_idh,serialized_content,task_action=nil)
      if task_template = get_matching_task_template?(assembly_idh,task_action)
        task_template.update(:content => serialized_content)
        task_template.id_handle()
      else
        task_action ||= default_task_action()
        ref,create_hash = ref_and_create_hash(serialized_content,task_action)
        create_hash.merge!(:ref => ref,:component_component_id => assembly_idh.get_id()) 
        task_template_mh = assembly_idh.create_childMH(:task_template)
        create_from_row(task_template_mh,create_hash,:convert=>true)
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
        :cols => [:id],
        :filter => [:and,[:eq,:component_component_id,assembly_idh.get_id],
                    [:eq,:task_action,task_action]]
      }
      task_template_mh = assembly_idh.createMH(:model_name => :task_template,:parent_model_name => :assembly)
      get_obj(task_template_mh,sp_hash)
    end
  end
end; end
