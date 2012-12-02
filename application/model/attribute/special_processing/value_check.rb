module DTK; class Attribute
  class SpecialProcessing
    class ValueCheck < self
      #returns [whether_special_processing,nil_or_value_check_error]
      def self.error_special_processing?(attr,new_val)
        error = nil
        if special_processing = needs_special_processing?(attr)
          error = error?(attr,new_val)
        end
        [special_processing,error]
      end

     private
      def self.needs_special_processing?(attr)
        if attr_info = attr_info(attr)
          attr_info[:filter].call(attr)
        end
      end
      def self.error?(attr,new_val)
        if legal_values = legal_values(attr)
          unless legal_values.include?(new_val)
            LegalValue::Error.new(attr,new_val,:legal_values => legal_values)
          end
        else
          raise Error.new("Not Implemented yet error checking for special cases when no legal values defined")
        end
      end

      def self.legal_values(attr)
        if legal_values_proc = (attr_info(attr)||{})[:legal_values]
          legal_values_proc.call(attr)
        end
      end
      
      def self.attr_info(attr)
        SpecialProcessingInfo[attr[:display_name].to_sym]
      end

      SpecialProcessingInfo = {
        :memory_size => {
          :filter => lambda{|a|a[:node_node_id]},
          :legal_values => lambda{|a|Node::Template.legal_memory_sizes(a.model_handle(:node))}
        },
        :os_type =>{
          :filter => lambda{|a|a[:node_node_id]},
          :legal_values => lambda{|a|node_os_type_legal_values(a)} 
        } 
      }
      def self.node_os_type_legal_values(attr)
        Node::Template.list(attr.id_handle().createMH(:node)).map{|n|n[:display_name]}
      end
    end
  end
end; end
