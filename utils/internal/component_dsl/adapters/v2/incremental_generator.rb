module DTK; class ComponentDSL; class V2
  class IncrementalGenerator
    def self.generate(aug_object)
      ref = aug_object.get_field?(:ref)
      body = klass(aug_object).new().generate(aug_object)
      {ref => body}
    end
   private
    def self.klass(object)
      class_last_part = object.class.to_s.split('::').last
      ret = nil
      begin 
        ret = const_get class_last_part
       rescue
        raise Error.new("Generation of type (#{class_last_part}) not treated")
      end
      ret
    end

    class LinkDef < self
      def generate(aug_link_def)
        content = PrettyPrintHash.new
        pls = assigns["possible_links"]
        unless pls.size == 1
          raise Error.new("feature_component_dsl_v2: TODO: not implemented yet when multiple possible links")
        end

        choice_info = choice_info(pls.first)
        unless ref = assigns["type"]
          raise Error.new("Expected type to be set in (#{assigns.inspect})")
        end
        unless component = choice_info[:remote_cmp_ref]
          raise Error.new("Expected choice_info[:remote_cmp_ref] is set in (#{assigns.inspect})")
        end
        content["component"] = component
        content["location"] = "remote"
        content["required"] = false if (!assigns["required"].nil?) and not assigns["required"]
        content["attribute_mappings"] = choice_info[:attribute_mappings]
        {ref => content}
        end
      
      def self.choice_info(assigns)
        remote_cmp_ref = qualified_component_ref(assigns.keys.first)
        info = assigns.values.first
        unless info.keys == ["attribute_mappings"]
          raise Error.new("feature_component_dsl_v2: TODO: not implemented yet when possibles links has keys (#{info.keys.join(",")})")
        end
        attribute_mappings = info["attribute_mappings"].map{|am|attribute_mapping(am,remote_cmp_ref)}
        {:remote_cmp_ref => remote_cmp_ref,:attribute_mappings => attribute_mappings}
      end

      def self.attribute_mapping(assigns,remote_cmp_ref)
        unless assigns.kind_of?(Hash) and assigns.size == 1
          raise Error.new("Unexpected form for attribute mapping (#{assigns.inspect})")
        end
        left_attr, dir = attribute_mapping_attr_info(assigns.keys.first,remote_cmp_ref)
        right_attr = attribute_mapping_attr_info(assigns.values.first)
        
        if dir == :output_to_input
          "$#{left_attr} -> #{right_attr}"
        else
          "#{left_attr} <- $#{right_attr}"
        end
      end

      #if remote_cmp_ref non-null returns [attr_ref,dir], otherwise just returns attr_ref
      def self.attribute_mapping_attr_info(var,remote_cmp_ref=nil)
        dir = nil
        attr_ref = nil
        parts = (var =~ /(^[^.]+)\.(.+$)/; [$1,$2])
        case parts[0]
        when ":remote_node",":local_node" 
          attr_ref = ["node",parts[1].gsub(/host_addresses_ipv4\.0/,"host_address")].join('.')
          dir = (remote_cmp_ref && (parts[0] == ":remote_node" ? :output_to_input : :input_to_output))
        else
          attr_ref = parts[1]
          if remote_cmp_ref
            dir = (remote_cmp_ref == qualified_component_ref(parts[0]).gsub(/^:/,"") ? :output_to_input : :input_to_output) 
          end
        end
        dir ? [attr_ref,dir] : attr_ref
      end
    end
  end
end; end; end
