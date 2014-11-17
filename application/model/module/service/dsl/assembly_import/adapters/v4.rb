module DTK; class ServiceModule
  class AssemblyImport
    r8_require('v3')
    class V4 < V3
      def self.parse_node_bindings_hash!(node_bindings_hash,opts={})      
        if hash = NodeBindings::DSL.parse!(node_bindings_hash,opts)
          DBUpdateHash.new(hash)
        end
      end
     private
      def self.import_component_attribute_info(cmp_ref,cmp_input)
        super
        ret_input_attribute_info(cmp_input).each_pair do |attr_name,attr_info|
          if base_tags = attr_info["tags"] || ([attr_info["tag"]] if attr_info["tag"])
            add_attribute_tags(cmp_ref,attr_name,base_tags)
          end
        end
      end
      
      def self.ret_input_attribute_info(cmp_input)
        ret_component_hash(cmp_input)["attribute_info"]||{}
      end
      def self.add_attribute_tags(cmp_ref,attr_name,tags)
        attr_info = output_component_attribute_info(cmp_ref)
        (attr_info[attr_name] ||= {:display_name => attr_name}).merge!(:tags => HierarchicalTags.new(tags))
      end

    end
  end
end; end
