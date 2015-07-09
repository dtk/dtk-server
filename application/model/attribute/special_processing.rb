module DTK; class Attribute
  class SpecialProcessing
    r8_nested_require('special_processing','value_check')
    r8_nested_require('special_processing','update')

    private

    def self.needs_special_processing?(attr)
      attr_info(attr)
    end

    def self.attr_info(attr)
      if type = attribute_type(attr)
        SpecialProcessingInfo[type][attr.get_field?(:display_name).to_sym]
      end
    end

    def self.attribute_type(attr)
      attr.update_object!(:node_node_id,:component_component_id)
      if attr[:node_node_id] then :node
      elsif attr[:component_component_id] then :component
      else
        Log.error('Unexepected that both :node_node_id and :component_component_id are nil')
        nil
      end
    end

    class LegalValues
      attr_reader :print_form
      def include?(val)
        @charachteristic_fn.call(val)
      end
      def self.create?(attr,attr_info)
        if attr_info
          if attr_info[:legal_values] || (attr_info[:legal_value_fn] && attr_info[:legal_value_error_msg])
            new(attr,attr_info)
          end
        end
      end

      private

      def initialize(attr,attr_info)
        if attr_info[:legal_values]
          legal_values = attr_info[:legal_values].call(attr)
          @charachteristic_fn = lambda{|v|legal_values.include?(v)}
          @print_form = legal_values
        else #attr_info[:legal_value_fn] and attr_info[:legal_value_error_msg]
          @charachteristic_fn = attr_info[:legal_value_fn]
          @print_form = [attr_info[:legal_value_error_msg]]
        end
      end
    end

    SpecialProcessingInfo = {
      node: {
        memory_size: {
          legal_values: lambda{|a|Node::Template.legal_memory_sizes(a.model_handle(:node))},
          proc: lambda{|a,v|Update::MemorySize.new(a,v).process()}
        },
        os_identifier: {
          legal_values: lambda{|a|Node::Template.legal_os_identifiers(a.model_handle(:node))},
          proc: lambda{|a,v|Update::OsIdentifier.new(a,v).process()}
        },
        cardinality: {
          legal_value_fn: lambda do |v|
            val =
              if v.is_a?(Fixnum) then v
              elsif v.is_a?(String) && v =~ /^[0-9]+$/ then v.to_i
              end
            val && val > 0
          end,
          legal_value_error_msg: 'Value must be a positive integer',
          proc: lambda{|a,v|Update::GroupCardinality.new(a,v).process()}
        }
      },
      component: {
      }
    }
  end
end; end
