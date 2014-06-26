module DTK; class Attribute
  class SpecialProcessing
    class ValueCheck < self
      # returns [whether_special_processing,nil_or_value_check_error]
      def self.error_special_processing?(attr,new_val)
        error = nil
        if special_processing = needs_special_processing?(attr)
          error = error?(attr,new_val)
        end
        [special_processing,error]
      end

     private
      def self.error?(attr,new_val)
        if legal_values = legal_values(attr)
          unless legal_values.include?(new_val)
            LegalValue::Error.new(attr,new_val,:legal_values => legal_values)
          end
        else
          raise Error.new("Not implemented yet error checking for special cases when no legal values defined")
        end
      end

      def self.legal_values(attr)
        if legal_values_proc = (attr_info(attr)||{})[:legal_values]
          legal_values_proc.call(attr)
        end
      end

      def self.ret_special_processing_info()
        SpecialProcessingInfo
      end
      SpecialProcessingInfo = {
        :memory_size => {
          :filter => lambda{|a|a[:node_node_id]},
          :legal_values => lambda{|a|Node::Template.legal_memory_sizes(a.model_handle(:node))}
        },
        :os_identifier =>{
          :filter => lambda{|a|a[:node_node_id]},
          :legal_values => lambda{|a|Node::Template.legal_os_identifiers(a.model_handle(:node))}
        } 
      }
    end
  end
end; end
