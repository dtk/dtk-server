module DTK
  class Node
    class Instance < self
      def self.create_linked_target_ref?(target,node,assembly)
        ndx_node_target_ref_array = Node::TargetRef.create_linked_target_refs?(target,assembly,[node])
        unless target_ref_array = ndx_node_target_ref_array[node[:id]]
          raise Error.new("Unexpected that create_linked_target_ref does not return element matching node[:id]")
        end
        unless target_ref_array.size == 1
          raise Error.new("Unexpected that ndx_node_target_ref_array.size not equal 1")
        end
        target_ref_array.first.create_object()
      end

      def self.component_list_fields()
        [:id,:display_name,:group_id,:external_ref,:ordered_component_ids]
      end
      
      def self.get(mh,opts={})
        sp_hash = {
          :cols => ([:id,:group_id,:display_name]+(opts[:cols]||[])).uniq,
          :filter => [:neq,:datacenter_datacenter_id,nil]
        }
        get_objs(mh,sp_hash)
      end
      
      def self.get_unique_instance_name(mh,display_name)
        display_name_regexp = Regexp.new("^#{display_name}")
        matches = get(mh,:cols=>[:display_name]).select{|r|r[:display_name] =~ display_name_regexp}
        if matches.empty?
          return display_name
        end
        index = 2
        matches.each do |r|
          instance_name = r[:display_name]
          if instance_name =~ /-([0-9]+$)/
            instance_index = $1.to_i
            if instance_index >= index
              index += 1
            end
          end
        end
        "#{display_name}-#{index.to_s}"
      end
    end
  end
end
