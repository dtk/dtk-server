module DTK; module CommandAndControlAdapter
  class Ec2
    class CreateNode < self
      r8_nested_require('create_node', 'processor')

      def self.run(task_action)
        single_run_responses = generate_create_node_processors(task_action).map(&:run)
        aggregate_responses(single_run_responses)
      end

      private

      def self.generate_create_node_processors(task_action)
        nodes = task_action.nodes()
        nodes.each do |node|
          node.update_object!(:os_type, :external_ref, :hostname_external_ref, :display_name, :assembly_id)
        end
        target = task_action.target()
        base_node = task_action.base_node()
        nodes.map { |node| Processor.new(base_node, node, target) }
      end

      def self.aggregate_responses(single_run_responses)
        if single_run_responses.size == 1
          single_run_responses.first
        else
          #TODO: just finds first error now
          if first_error = single_run_responses.find { |r| r[:status] == 'failed' }
            first_error
          else
            #assuming all ok responses are the same
            single_run_responses.first
          end
        end
      end
    end
  end
end; end
