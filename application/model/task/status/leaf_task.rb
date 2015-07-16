module DTK; class Task::Status
  class LeafTask
    dtk_nested_require('leaf_task', 'executable_action')

    def initialize(ret_nested_hash, leaf_task)
      @ret_nested_hash = ret_nested_hash
      @leaf_task       = leaf_task
    end
    
    def self.add_details!(ret_nested_hash, leaf_task)
      new(ret_nested_hash, leaf_task).add_details!
    end
    
    def add_details!
      ExecutableAction.add_components_and_actions!(@ret_nested_hash, @leaf_task)
      set?(:action_results, action_results?())
      # set(:errors, errors?())
      @ret_nested_hash
    end
    
    private

    def action_results?
      if action_results = @leaf_task[:action_results]
        action_results.map { |a| Aux.hash_subset(a, ActionResultFields) }
      end
    end
    ActionResultFields = [:status, :stdout, :stderr, :description]
    
    def set?(key, value)
      unless value.nil?
        @ret_nested_hash[key] = value
      end
    end

  end
end; end    
