module DTK
  class Node
    class Template < self
      r8_nested_require('template', 'factory')

      def self.create_or_update_node_template(target, node_template_name, image_id, opts = {})
        Factory.create_or_update(target, node_template_name, image_id, opts)
      end

      def self.delete_node_template(node_binding_ruleset)
        sp_hash = {
          cols: [:id, :group_id, :display_name],
          filter: [:eq, :node_binding_rs_id, node_binding_ruleset.id]
        }
        node_images = get_objs(node_binding_ruleset.model_handle(:node), sp_hash)
        unless node_images.size == 1
          Log.error("Unexpected that there are (#{node_images.size}) node images that match #{node_binding_ruleset.get_field?(:ref)}")
        end
        node_images.map { |n| delete_instance(n.id_handle()) }
        delete_instance(node_binding_ruleset.id_handle())
      end

      def self.list(model_handle, opts = {})
        ret = []
        node_bindings = nil

        if opts[:target_id]
          sp_hash = { cols: [:node_bindings], filter: [:eq, :datacenter_datacenter_id, opts[:target_id].to_i] }
          node_bindings = get_objs(model_handle.createMH(:node), sp_hash)
          unq_bindings = node_bindings.inject({}) { |tmp, nb| tmp.merge(nb[:node_binding_rs_id] => nb[:node_binding_ruleset]) }
          node_bindings = unq_bindings.values
        elsif opts[:is_list_all] && opts[:is_list_all].to_s == 'true'
          sp_hash = { cols: [:node_bindings], filter: [:neq, :datacenter_datacenter_id, nil] }
          node_bindings = get_objs(model_handle.createMH(:node), sp_hash)
          unq_bindings = node_bindings.inject({}) { |tmp, nb| tmp.merge(nb[:node_binding_rs_id] => nb[:node_binding_ruleset]) }
          node_bindings = unq_bindings.values
        else
          sp_hash = {
            cols: [:id, :ref, :display_name, :rules, :os_type]
          }
          sp_hash.merge!(filter: opts[:filter]) if opts[:filter]
          node_bindings = get_objs(model_handle.createMH(:node_binding_ruleset), sp_hash, keep_ref_cols: true)
        end

        node_bindings.each do |nb|
          # TODO: fix so that have a unique id for each
          unique_id = ((nb[:rules].size == 1) && nb[:id])
          nb[:rules].each do |r|
            # Amar & Haris: Skipping node template in case when target name filter is sent in method request from CLI
            next if (opts[:target_id] && r[:datacenter_datacenter_id] == opts[:target_id].to_i)
            el = {
              display_name: nb[:display_name] || nb[:ref], #TODO: may just use display_name after fill in this column
              os_type: nb[:os_type]
            }.merge(r[:node_template])
            el.merge!(id: unique_id) if unique_id
            ret << el
          end
        end
        ret.sort { |a, b| a[:display_name] <=> b[:display_name] }
      end

      def self.image_type(target)
        "#{target.iaas_properties.type()}_image"
      end

      def self.get_public_library(model_handle)
        Library.get_public_library(model_handle.createMH(:library))
      end
      private_class_method :get_public_library

      def self.legal_os_identifiers(model_handle)
        public_library = get_public_library(model_handle)
        sp_hash = {
          cols: [:id, :os_identifier],
          filter: [:and, [:eq, :type, 'image'], [:eq, :library_library_id, public_library[:id]]]
        }
        get_images(model_handle).map { |r| r[:os_identifier] }.compact.uniq
      end

      def self.get_images(model_handle)
        public_library = Library.get_public_library(model_handle.createMH(:library))
        sp_hash = {
          cols: [:id, :group_id, :os_identifier, :external_ref],
          filter: [:and, [:eq, :type, 'image'], [:eq, :library_library_id, public_library[:id]]]
        }
        get_objs(model_handle.createMH(:node), sp_hash)
      end
      private_class_method :get_images

      # returns [image_id, os_type]
      def self.find_image_id_and_os_type(os_identifier, target)
        opts_get = {
          cols: [:id, :group_id, :rules, :os_type],
          filter: [:eq, :os_identifier, os_identifier]
        }
        ret = nil
        get_node_binding_rulesets(target, opts_get).find do |nb_rs|
          if matching_rule = CommandAndControl.find_matching_node_binding_rule(nb_rs[:rules], target)
            ret = [matching_rule[:node_template][:image_id], nb_rs[:os_type]]
          end
        end
        ret
      end

      def self.get_matching_node_binding_rules(target, opts = {})
        ret = []
        get_node_binding_rulesets(target, opts).each do |nb_rs|
          if matching_rule = CommandAndControl.find_matching_node_binding_rule(nb_rs[:rules], target)
            ret << nb_rs.merge(matching_rule: matching_rule)
          end
        end
        ret
      end

      def self.get_node_binding_rulesets(target, opts = {})
        public_library = Library.get_public_library(target.model_handle(:library))
        filter = [:eq, :library_library_id, public_library.id()]
        if opts[:filter]
          filter = [:and, filter, opts[:filter]]
        end
        sp_hash = {
          cols: opts[:cols] || (NodeBindingRuleset.common_columns + [:ref]),
          filter: filter
        }
        get_objs(target.model_handle(:node_binding_ruleset), sp_hash, keep_ref_cols: true)
      end
      private_class_method :get_node_binding_rulesets

      def self.legal_memory_sizes(model_handle)
        public_library = Library.get_public_library(model_handle.createMH(:library))
        sp_hash = {
          cols: [:id, :external_ref],
          filter: [:and, [:eq, :type, 'image'], [:eq, :library_library_id, public_library[:id]]]
        }
        get_objs(model_handle.createMH(:node), sp_hash).map do |r|
          if external_ref = r[:external_ref]
            external_ref[:size]
          end
        end.compact.uniq
      end

      def self.find_matching_node_template(target, opts = {})
        if node_target = opts[:node_target]
          pp [:node_target, node_target]
          fail Error.new('here need to write code that uses node_target to return results')
        end

        node_binding_rs = opts[:node_binding_ruleset]
        ret = node_binding_rs && node_binding_rs.find_matching_node_template(target)
        ret || null_node_template(target.model_handle(:node))
      end

      def self.null_node_template(model_handle)
        sp_hash = {
          cols: [:id, :group_id, :display_name],
          filter: [:eq, :display_name, 'null-node-template']
        }
        node_mh = model_handle.createMH(:node)
        get_obj(node_mh, sp_hash)
      end
      private_class_method :null_node_template

      def self.image_upgrade(model_handle, old_image_id, new_image_id)
        nb_mh = model_handle.createMH(:node_binding_ruleset)
        matching_node_bindings = get_objs(nb_mh, cols: [:id, :rules]).select do |nb|
          nb[:rules].find { |r| r[:node_template][:image_id] == old_image_id }
        end
        if matching_node_bindings.empty?
          fail ErrorUsage.new("Cannot find reference to image_id (#{old_image_id})")
        end

        image_type = matching_node_bindings.first[:rules].first[:node_template][:type].to_sym

        # TODO: commented out below until can use new signature where pass in target to
        # get context, which includes image_type and if ec2 region
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
        update_from_rows(nb_mh, matching_node_bindings)

        # find and update nodes that are images
        sp_hash = {
          cols: [:id, :external_ref],
          filter: [:eq, :type, 'image']
        }
        matching_images = get_objs(model_handle, sp_hash).select do |r|
          r[:external_ref][:image_id] == old_image_id
        end
        unless matching_images.empty?
          matching_images.each { |r| r[:external_ref][:image_id] = new_image_id }
          update_from_rows(model_handle, matching_images)
        end
      end
    end
  end
end
