module DTKModule
  class Ec2::Node::InstanceInfo
    module OpState
      module Mixin
        def instance_state_matches?(states)
          OpState.matches?(aws_ec2_types_instance, states)
        end
        
        def in_a_run_state?
          OpState.matches?(aws_ec2_types_instance, OpState.states(:run))
        end
        
        def in_a_stop_state?
          OpState.matches?(aws_ec2_types_instance, OpState.states(:stop))
        end
        
        def in_a_terminate_state?
          OpState.matches?(aws_ec2_types_instance, OpState.states(:terminate))
        end
      end

      STATE_TO_CODE = {
        'pending'       => 0, 
        'running'       => 16,
        'shutting-down' => 32,
        'terminated'    => 48,
        'stopping'      => 64,
        'stopped'       => 80
      }
      STATES = STATE_TO_CODE.keys

      def self.matches?(aws_ec2_types_instance, states)
        raise_error_if_bad_state(states)
        states.map{ |state| STATE_TO_CODE[state]}.include?(aws_ec2_types_instance.state.code)
      end

      STATE_TYPES = {
        run: ['running'],
        stop: ['stopping', 'stopped'],
        terminate: ['shutting-down', 'terminated'] 
      }

      def self.states(type)
        STATE_TYPES[type] || fail("Illegal state type '#{type}'")
      end

      private

      def self.raise_error_if_bad_state(states)
        bad_states = states - STATES
        if bad_states.size == 1
          fail "The term '#{bad_states.first}' is an illegal EC2 instance state"
        elsif bad_states.size > 1
          fail "The terms (#{bad_states.join(', ')} are illegal EC2 instance states"
        end
      end

    end
  end
end
