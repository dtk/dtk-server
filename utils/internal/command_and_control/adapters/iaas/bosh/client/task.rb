module DTK; class CommandAndControl::IAAS::Bosh
  class Client
    module TaskMixin
      def poll_task_until_steady_state(id, output_type = nil)
        Task.poll_task_until_steady_state(self, id, output_type)
      end
    end
    
    class Task
      NumTimesToPoll = 30
      SleepInterval  = 1
      module State
        Timeout = 'timeout'
      end
      module States
        Error       = ['error']
        SteadyState = ['done', 'processing'] + Error 
      end

      # Represents end state
      def initialize(task_result_hash)
        @task_result_hash = task_result_hash
      end

      def self.poll_task_until_steady_state(client, task_id, output_type = nil)
        process = true
        count = 0
        while process
          count += 1
          task_result_hash = client.task(task_id)
          pp [:bosh_task, count, task_result_hash]
          sleep SleepInterval
          process = false if count > NumTimesToPoll or States::SteadyState.include?(task_state(task_result_hash))
        end
        if count > NumTimesToPoll
          new('state' => State::Timeout)
        else
          new(task_result_hash)
        end
      end

      # Returns error message if there is an error
      def error?
        if States::Error.include?(task_state)
          result
        end 
      end

      private

      def result
        @task_result_hash['result']
      end

      def task_state
        self.class.task_state(@task_result_hash)
      end
      def self.task_state(task_result_hash)
        task_result_hash['state']
      end
    end
  end
end; end
