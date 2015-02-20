module DTK; class ConfigAgent; module Adapter
  class DtkProvider
    module InterpretResults
      module Mixin
        def action_results(result,action)
          data = data_field_in_results(result)
          unless data.kind_of?(Hash)
            Log.error_pp(["Unexpected that data field is not a hash:",data])
            return nil
          end
          data[:results]
        end
        
        def errors_in_result?(result,action)
          # TODO: action passed in so can look to see at 'action action_status interpretation"
          default_errors_action_status?(result)
        end
        
        def interpret_error(error_in_result,components)
          error_in_result
        end

       private
        def default_errors_action_status?(results)
          if results_data = results[:results]
            # only last one can be failure
            last_results = (results_data.kind_of?(Array) ? results_data.last : results_data)
            status = last_results['status']
            if status and last_results['status'].to_s != '0'
              stderr = last_results['stderr']||''
              err_msg = (stderr.empty? ? "Error in action; syscall status = #{status.to_s}" : stderr)
              [err_msg]                
            end
          end
        end

        def data_field_in_results(result)
          # TODO: will be deprecating the [:data][:data] form
          (result[:data]||{})[:data]||result[:data]||{}
        end

      end 
    end
  end
end; end; end
