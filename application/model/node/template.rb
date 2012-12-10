module DTK
  class Node
    class Template < self
      def self.list(model_handle,opts={})
        ret = Array.new
        sp_hash = {
          :cols => [:id,:ref,:display_name,:rules,:os_type]
        }
        sp_hash.merge!(:filter => opts[:filter]) if opts[:filter]

        node_bindings = get_objs(model_handle.createMH(:node_binding_ruleset),sp_hash,:keep_ref_cols => true)
        node_bindings.each do |nb|
          nb[:rules].each do |r|
            el = {
              :display_name => nb[:display_name]||nb[:ref], #TODO: may just use display_name after fill in this column
              :os_type => nb[:os_type],
            }.merge(r[:node_template])
            ret << el
          end
        end
        ret
      end

      def self.image_upgrade(model_handle,old_image_id,new_image_id)
        nb_mh = model_handle.createMH(:node_binding_ruleset)
        matching_node_bindings = get_objs(nb_mh,:cols => [:id,:rules]).select do |nb| 
          nb[:rules].find{|r|r[:node_template][:image_id] == old_image_id}
        end
        if matching_node_bindings.empty?
          raise ErrorUsage.new("Cannot find reference to image_id (#{old_image_id})")
        end

        image_type = matching_node_bindings.first[:rules].first[:node_template][:type].to_sym
        unless CommandAndControl.existing_image?(new_image_id,image_type)
          raise ErrorUsage.new("Image id (#{new_image_id}) does not exist")
        end

        #update daatstructute than model
        matching_node_bindings.each do |nb|
          nb[:rules].each do |r|
            nt = r[:node_template]
            if nt[:image_id] == old_image_id
              nt[:image_id] = new_image_id
            end
          end
        end
        update_from_rows(nb_mh,matching_node_bindings)

        #find and update nodes that are images
        sp_hash = {
          :cols => [:id,:external_ref],
          :filter => [:eq, :type, "image"]
        }
        matching_images = get_objs(model_handle,sp_hash).select do |r|
          r[:external_ref][:image_id] == old_image_id
        end
        unless matching_images.empty?
          matching_images.each{|r|r[:external_ref][:image_id] = new_image_id}
          update_from_rows(model_handle,matching_images)
        end
      end
    end
  end
end
