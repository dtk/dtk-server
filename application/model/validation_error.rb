module XYZ
  class ValidationError < HashObject 
    def self.find_missing_required_attributes(commit_task)
      component_actions =  commit_task.component_actions
      ret = Array.new 
      component_actions.each do |action|
        action[:attributes].each do |attr|
          #TODO: need to distingusih between legitimate nil value and unset
          if attr[:required] and attr[:attribute_value].nil?
            error_input =
              {:external_ref => attr[:external_ref],
              :attribute_id => attr[:id],
              :component_id => (action[:component]||{})[:id],
              :node_id => (action[:node]||{})[:id]
            }
            ret <<  MissingRequiredAttribute.new(error_input)
          end
        end
      end
      ret.empty? ? nil : ret
    end

    def self.debug_inspect(error_list)
      ret = ""
      error_list.each{|e| ret << "#{e.class.to_s}: #{e.inspect}\n"}
      ret
    end
   private
    def initialize(hash)
      super(error_fields.inject({}){|ret,f|ret.merge(f => hash[f]) if hash[f]})
    end
    def error_fields()
      Array.new
    end
   public
    class MissingRequiredAttribute < ValidationError
      def error_fields()
        [:external_ref,:attribute_id,:component_id,:node_id]
      end
    end
  end
end
