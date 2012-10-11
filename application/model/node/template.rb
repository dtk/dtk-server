module DTK
  class Node
    class Template < self
      def self.list(model_handle)
        ret = Array.new
        sp_hash = {
          :cols => [:id,:ref,:display_name,:rules,:os_type]
        }
        node_bindings = get_objs(model_handle.createMH(:node_binding_ruleset),sp_hash,:keep_ref_cols => true)
        node_bindings.each do |nb|
          nb[:rules].each do |r|
            el = {
              :display_name => nb[:display_name]||nb[:ref], #TODO: may just use display_name after fil in this column
              :os_type => nb[:os_type],
            }.merge(r[:node_template])
            ret << el
          end
        end
        ret
      end
      def self.image_upgrade(model_handle,old_image_id,new_image_id)
        sp_hash = {
          :cols => [:id,:ref,:display_name,:rules,:os_type]
        }
        node_bindings = get_objs(model_handle.createMH(:node_binding_ruleset),sp_hash)
        matching_node_bindings = node_bindings.select do |nb| 
          nb[:rules].find{|r|r[:node_template][:image_id] == old_image_id}
        end
        if matching_node_bindings.empty?
          raise ErrorUsage.new("Cannot find reference to image_id (#{old_image_id})")
        end
        pp matching_node_bindings
        image_type = matching_node_bindings.first[:rules].first[:node_template][:type].to_sym
        #TODO: check if new_image_id is a legitimate image id 
        unless CommandAndControl.existing_image?(new_image_id,image_type)
          raise ErrorUsage.new("Image id (#{new_image_id}) does not exist")
        end
      end
    end
  end
end
