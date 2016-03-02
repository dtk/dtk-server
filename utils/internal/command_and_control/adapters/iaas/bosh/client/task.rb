module DTK; class CommandAndControl::IAAS::Bosh
  class Client
    module TaskMixin
      private

      def poll_task_until_steady_state(id)
        Task.poll_task_until_steady_state(self, id)
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
        SteadyState = ['done', 'processing'] + Error + [State::Timeout] 
      end

      # Represents end state
      def initialize(client, task_result_hash)
        @client = client
        @task_result_hash = task_result_hash
      end
      private :initialize

      def self.poll_task_until_steady_state(client, task_id)
        process = true
        count = 0
        while process
          count += 1
          task_result_hash = client.task(task_id)
pp [:task_result_hash, task_result_hash]
          sleep SleepInterval
          process = false if count > NumTimesToPoll or States::SteadyState.include?(task_state(task_result_hash))
        end
        if count > NumTimesToPoll
          new(client, 'state' => State::Timeout)
        else
          new(client, task_result_hash)
        end
      end

      # Returns error message if there is an error
      def error?
        task_result_field if States::Error.include?(task_state)
      end

      def result
        result_field = task_result_field || ''
        result_field.empty? ? @client.task(task_id, 'result') : result_field
      end

      private

      def task_id
        @task_result_hash['id']
      end

      def task_result_field
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

