module DTK; class Attribute
  class SpecialProcessing
    r8_nested_require('special_processing','value_check')
    r8_nested_require('special_processing','update')
   private

    def self.needs_special_processing?(attr)
      if attr_info = attr_info(attr)
        not attr_info.nil?
      end
    end

    def self.attr_info(attr)
      if type = attribute_type(attr)
        SpecialProcessingInfo[type][attr[:display_name]]
      end
    end

    def self.attribute_type(attr)
      if attr[:node_node_id] then :node
      elsif attr[:component_component_id] then :component
      else
        Log.error("Unexepected that both :node_node_id and :component_component_id are nil")
        nil
      end
    end

    SpecialProcessingInfo = {
      :node => {
        :memory_size => {
          :legal_values => lambda{|a|Node::Template.legal_memory_sizes(a.model_handle(:node))},
          :proc => lambda{|a,v|MemorySize.process(a,v)}
        },
        :os_identifier =>{
          :legal_values => lambda{|a|Node::Template.legal_os_identifiers(a.model_handle(:node))},
          :proc => lambda{|a,v|OsIdentifier.process(a,v)}
        },
        :cardinality =>{
          :legal_values => lambda{|a| a.kind_of?(Fixnum) or (a.kind_of?(String) and a =~ /^[0-9]$/)},
          :proc => lambda{|a,v|nil}
        } 
      },
      :component => {
      }
    }
  end
end; end
