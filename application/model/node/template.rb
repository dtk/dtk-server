module DTK
  class Node
    class Template < self
      def self.list(model_handle,opts={})

        ret = Array.new
        node_bindings = nil
       
        if opts[:target_id]
          sp_hash = { :cols => [:node_bindings], :filter => [:eq, :datacenter_datacenter_id, opts[:target_id].to_i]}
          node_bindings = get_objs(model_handle.createMH(:node), sp_hash)
          unq_bindings = node_bindings.inject({}) { |tmp,nb| tmp.merge(nb[:node_binding_rs_id] => nb[:node_binding_ruleset])}            
          node_bindings = unq_bindings.values
        elsif opts[:is_list_all] == "true"
          sp_hash = { :cols => [:node_bindings], :filter => [:neq, :datacenter_datacenter_id, nil]}
          node_bindings = get_objs(model_handle.createMH(:node), sp_hash)
          unq_bindings = node_bindings.inject({}) { |tmp,nb| tmp.merge(nb[:node_binding_rs_id] => nb[:node_binding_ruleset])}            
          node_bindings = unq_bindings.values
        else
          sp_hash = {
            :cols => [:id,:ref,:display_name,:rules,:os_type]
          }
          sp_hash.merge!(:filter => opts[:filter]) if opts[:filter]
          node_bindings = get_objs(model_handle.createMH(:node_binding_ruleset),sp_hash,:keep_ref_cols => true)
        end

        node_bindings.each do |nb|
          # TODO: fix so taht have a unique id for each
          unique_id = ((nb[:rules].size == 1) && nb[:id])
          nb[:rules].each do |r|
            # Amar & Haris: Skipping node template in case when target name filter is sent in method request from CLI
            next if (opts[:target_id] && r[:datacenter_datacenter_id] == opts[:target_id].to_i)
            el = {
              :display_name => nb[:display_name]||nb[:ref], #TODO: may just use display_name after fill in this column
              :os_type => nb[:os_type],
            }.merge(r[:node_template])
            el.merge!(:id => unique_id) if unique_id
            ret << el
          end
        end
        ret.sort{|a,b|a[:display_name] <=> b[:display_name]}
      end

      def self.legal_os_identifiers(model_handle)
        # ALDIN: I will comment this return statement until we figure out if we need this,
        # because it's causing issues when we add new OS it will return OS list that is already assigned to
        # @legal_os_types variable which does not containe newly added OS
        # return @legal_os_types if @legal_os_types
        
        public_library = Library.get_public_library(model_handle.createMH(:library))
        sp_hash = {
          :cols => [:id,:os_identifier],
          :filter => [:and,[:eq,:type,"image"],[:eq,:library_library_id,public_library[:id]]]
        }
        @legal_os_types = get_objs(model_handle.createMH(:node),sp_hash).map{|r|r[:os_identifier]}.compact.uniq
      end

      # returns [image_id, os_type]
      def self.find_image_id_and_os_type(os_identifier,target)
        public_library = Library.get_public_library(target.model_handle(:library))
        sp_hash = {
          :cols => [:id,:rules,:os_type],
          :filter => [:and,[:eq,:os_identifier,os_identifier],[:eq,:library_library_id,public_library[:id]]]
        }
        ret = nil
        get_objs(target.model_handle(:node_binding_ruleset),sp_hash).find do |nb_rs|
          if matching_rule = CommandAndControl.find_matching_node_binding_rule(nb_rs[:rules],target)
            ret = [matching_rule[:node_template][:image_id],nb_rs[:os_type]]
          end
        end
        ret
      end

      def self.legal_memory_sizes(model_handle)
        return @legal_memory_sizes if @legal_memory_sizes
        public_library = Library.get_public_library(model_handle.createMH(:library))
        sp_hash = {
          :cols => [:id,:external_ref],
          :filter => [:and,[:eq,:type,"image"],[:eq,:library_library_id,public_library[:id]]]
        }
        @legal_memory_sizes = get_objs(model_handle.createMH(:node),sp_hash).map do |r|
          if external_ref = r[:external_ref]
            external_ref[:size]
          end
        end.compact.uniq
      end

      def self.find_matching_node_template(target,node_binding_rs=nil)
        ret = node_binding_rs && node_binding_rs.find_matching_node_template(target)
        ret || null_node_template(target.model_handle(:node))
      end

      def self.null_node_template(model_handle)
        sp_hash = {
          :cols => [:id,:group_id,:display_name],
          :filter => [:eq,:display_name, "null-node-template"]
        }
        node_mh = model_handle.createMH(:node)
        get_obj(node_mh,sp_hash)
      end
      private_class_method :null_node_template

      def self.image_upgrade(model_handle,old_image_id,new_image_id)
        nb_mh = model_handle.createMH(:node_binding_ruleset)
        matching_node_bindings = get_objs(nb_mh,:cols => [:id,:rules]).select do |nb| 
          nb[:rules].find{|r|r[:node_template][:image_id] == old_image_id}
        end
        if matching_node_bindings.empty?
          raise ErrorUsage.new("Cannot find reference to image_id (#{old_image_id})")
        end

        image_type = matching_node_bindings.first[:rules].first[:node_template][:type].to_sym
        # TODO: commented out below until fix DTK-434
        # unless CommandAndControl.existing_image?(new_image_id,image_type)
        #  raise ErrorUsage.new("Image id (#{new_image_id}) does not exist")
        # end

        # update daatstructute than model
        matching_node_bindings.each do |nb|
          nb[:rules].each do |r|
            nt = r[:node_template]
            if nt[:image_id] == old_image_id
              nt[:image_id] = new_image_id
            end
          end
        end
        update_from_rows(nb_mh,matching_node_bindings)

        # find and update nodes that are images
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
