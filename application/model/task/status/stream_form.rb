module DTK; class Task
  class Status
    module StreamForm
      def self.status(top_level_task,opts={})
        Log.info("stub for Status::StreamForm.status")
        task_structure = top_level_task.get_hierarchical_structure()
        status_opts = Opts.new(:no_components => false, :no_attributes => true)
        status_opts.merge!(:summarize_node_groups => true) if (opts[:detail_level]||{})[:summarize_node_groups]
        TableForm.status(task_structure,status_opts)
      end
    end
  end
end; end
