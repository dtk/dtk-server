module DTK; class ConfigAgent; module Adapter
  class DtkProvider
    module InterpretResults
      module Mixin
        def action_results(result, _action)
          # DEBUG SNIPPET >>> REMOVE <<<
          require (RUBY_VERSION.match(/1\.8\..*/) ? 'ruby-debug' : 'debugger');Debugger.start; debugger
          data = data_field_in_results(result)
          unless data.is_a?(Hash)
            Log.error_pp(['Unexpected that data field is not a hash:', data])
            return nil
          end
          data[:results]
        end

        def errors_in_result?(result, _action)
          # TODO: action passed in so can look to see at 'action action_status interpretation"
          default_errors_action_status?(result)
        end

        def interpret_error(error_in_result, _components)
          error_in_result
        end

        private

        def default_errors_action_status?(results)
          if results_data = results[:results]
            if results_data.is_a?(Array)
              err_msgs = []
              results_data.each do |result|
                status = result['status']
                if status && result['status'].to_s != '0'
                  stderr = result['stderr'] || ''
                  err_msgs << (stderr.empty? ? "Error in action; syscall status = #{status}" : stderr)
                end
              end
              err_msgs unless err_msgs.empty?
            else
              status = results_data['status']
              if status && results_data['status'].to_s != '0'
                stderr = results_data['stderr'] || ''
                err_msg = (stderr.empty? ? "Error in action; syscall status = #{status}" : stderr)
                [err_msg]
              end
            end
          end
        end

        def data_field_in_results(result)
          # TODO: will be deprecating the [:data][:data] form
          result[:data] || {}
        end
      end
    end
  end
end; end; end
