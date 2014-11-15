module DTK
  class LinkDefLink
    class AttributeMapping < HashObject
      def self.reify(object)
        if object.kind_of?(AttributeMapping)
          object
        elsif object.kind_of?(Hash)
          new(object)
        else
          raise Error.new("Unexpected object type (#{object.class})")
        end
      end

      def match_attribute_patterns?(dep_attr_pattern,antec_attr_pattern)
        if dep_attr_pattern.match_attribute_mapping_endpoint?(self[:input]) and
            antec_attr_pattern.match_attribute_mapping_endpoint?(self[:output])
          self
        end
      end

      def self.ret_links_array(attribute_mappings,context,opts={})
        contexts = (context.has_node_group_form?() ? context.node_group_contexts_array() : [context])
        contexts.map{|context|attribute_mappings.map{|am|am.ret_link(context,opts)}.compact}
      end

      class AugmentedLink < Hash
        def initialize(attribute_mapping)
          super()
          @attribute_mapping = attribute_mapping
        end
        def link_function?(fn_based_on_type)
          if fn = @attribute_mapping.link_function?(fn_based_on_type)
            {:function => fn}
          end
        end
      end
      # returns AugmentedLink
      def ret_link(context,opts={})
        input_attr,input_path = get_attribute_with_unravel_path(:input,context)
        output_attr,output_path = get_attribute_with_unravel_path(:output,context)
        
        err_msgs = Array.new
        unless input_attr
          err_msgs << "attribute (#{pp_form(:input)}) does not exist"
        end
        unless output_attr
          err_msgs << "attribute (#{pp_form(:output)}) does not exist"
        end
        unless err_msgs.empty?
          err_msg = err_msgs.join(" and ").capitalize
          if opts[:raise_error]
            raise ErrorUsage.new(err_msg)
          else
            Log.error(err_msg)
            return nil
          end
        end

        ret = AugmentedLink.new(self).merge(:input_id => input_attr[:id],:output_id => output_attr[:id])
        ret.merge!(:input_path => input_path) if input_path
        ret.merge!(:output_path => output_path) if output_path
        ret
      end

      def link_function?(fn_based_on_type)
        if fn_based_on_type.to_sym == :eq
          if output_term_index = (self[:output]||{})[:term_index] 
            if output_var = output_term_index.split('.').last
              LinkFunction::Eq.link_function?(output_var)
            end
          end
        end
      end
      module LinkFunction
        module Eq
          # example abc${output_var}def",
          def self.link_function?(output_var)
            if output_var =~ /(^[^\$]*)\$\{[^\}]+\}(.*$)/
              text_parts = [$1,$2]
              AttributeLink::PropagateProcessor::SpecifiedFunction::VarEmbeddedInText.function_def(text_parts)
            end
          end
        end
      end

      def pp_form(direction)
        ret = 
          if attr = self[direction]
            cmp_type = attr[:component_type]
            attr_name = attr[:attribute_name]
            if cmp_type and attr_name
              "#{Component.component_type_print_form(cmp_type)}.#{attr_name}"
            end
          end
        ret||""
      end

     private
      # returns [attribute,unravel_path]
      def get_attribute_with_unravel_path(dir,context)
        index_map_path = nil
        attr = nil
        ret = [attr,index_map_path]
        attr = context.find_attribute(self[dir][:term_index])
        index_map_path = self[dir][:path]
        # TODO: if treat :create_component_index need to put in here process_unravel_path and process_create_component_index (from link_defs.rb)
        [attr,index_map_path && AttributeLink::IndexMapPath.create_from_array(index_map_path)]
      end
    end
  end
end

