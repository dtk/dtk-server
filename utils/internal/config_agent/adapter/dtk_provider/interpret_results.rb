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
          data['results']
        end
        
        def errors_in_result?(result,action)
          #TODO: stub
          nil
        end
        
        def interpret_error(error_in_result,components)
          #TODO: stub
          pp [error_in_result,components]
          ret = error_in_result
          ret
        end

       private
        def data_field_in_results(result)
          # TODO: will be deprecating the [:data][:data] form
          (result[:data]||{})[:data]||result[:data]||{}
        end

      end 
    end
  end
end; end; end
