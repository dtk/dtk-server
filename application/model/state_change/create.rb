module DTK
  class StateChange
    module CreateClassMixin
      def create_pending_change_item(new_item_hash,opts={})
        target_idh = opts[:target_idh] || Create.target_idh(new_item_hash[:parent])
        Create.new(target_idh).pending_change_items([new_item_hash],opts).first
      end

      # if pending change object exists, it returns it and updates its status to 'pending' if needed
      # otherwise it creates a new one and returns it
      def create_pending_change_item?(new_item_hash,opts={})
        target_idh = opts[:target_idh] || Create.target_idh(new_item_hash[:parent])
        Create.new(target_idh).pending_change_item?(new_item_hash,opts)
      end

      # assumption is that all items belong to same target
      def create_pending_change_items(new_item_hashes,opts={})
        ret = []
        return ret if new_item_hashes.empty?
        target_idh = opts[:target_idh] || Create.target_idh(new_item_hashes.first[:parent])
        Create.new(target_idh).pending_change_items(new_item_hashes,opts)
      end
      #TODO: ### may deprecate below
      def create_converge_state_changes(node_idhs)
        return if node_idhs.empty?
        target_idh = Create.target_idh(node_idhs.first)
        Create.new(target_idh).converge_state_changes(node_idhs)
      end
    end

    class Create
      def initialize(target_idh)
        @target_idh = target_idh
        @target_id = target_idh.get_id()
      end

      def self.target_idh(parent_idh)
        parent_idh.get_top_container_id_handle(:target)
      end

      def pending_change_item?(new_item_hash,opts={})
        create_row = change_item_create_row(new_item_hash,opts)
        cols = ([:id,:group_id,:display_name,:status,:node_id,:component_id] + (opts[:returning_sql_cols]||[])).uniq
        sp_hash = {
          cols: cols,
          filter: [:and,
                   [:eq,:ref,create_row[:ref]],
                   [:eq,:datacenter_datacenter_id,create_row[:datacenter_datacenter_id]]]
        }
        
        model_handle = @target_idh.createMH(model_name: :state_change, parent_model_name: :target)
        if ret = Model.get_obj(model_handle,sp_hash)
          unless ret[:status] == 'pending'
            ret[:status] = 'pending'
            ret.update(status: 'pending')
          end
          ret
        else
          opts_create = {convert: true}.merge(Aux.hash_subset(opts,:returning_sql_cols))
          Model.create_from_row(model_handle,create_row,opts_create).create_object()
        end
      end

      def pending_change_items(new_item_hashes,opts={})
        create_rows = new_item_hashes.map{|item|change_item_create_row(item,opts)}
        model_handle = @target_idh.createMH(model_name: :state_change, parent_model_name: :target)
        opts_create = {convert: true}.merge(Aux.hash_subset(opts,:returning_sql_cols))
        Model.create_from_rows(model_handle,create_rows,opts_create)
      end
      
      def change_item_create_row(item,_opts={})
        new_item = item[:new_item]
        model_name = new_item[:model_name]
        parent = item[:parent]
        object_id_col = "#{model_name}_id".to_sym
        
        ret = {
          :ref => ref(model_name,item),
          :display_name => display_name(model_name,item),
          :status => "pending",
          :type =>  item[:type] || type(model_name),
          :object_type => model_name.to_s,
          object_id_col => new_item.get_id(),
          :datacenter_datacenter_id => @target_id
        }
        if parent[:model_name] == :state_change
          ret.merge!(state_change_id: parent.get_id())
        end
        ret.merge!(change: item[:change]) if item[:change]
        ret.merge!(change_paths: item[:change_paths]) if item[:change_paths]
        ret
      end

      def display_name(model_name,item)
        display_name_prefix = 
          case model_name
            when :attribute then "setting-attribute"
            when :component then "install-component"
            when :node then "create-node"
          end
        item_display_name = item[:new_item].get_field?(:display_name)
        display_name_prefix + (item_display_name ? "(#{item_display_name})" : "")
      end

      def ref(_model_name,item)
        object_id = item[:new_item].get_id().to_s
        parent_id = item[:parent].get_id().to_s
        "#{RefPrefix}#{parent_id}--#{object_id}"
      end
      RefPrefix = "state_change"

      def type(model_name)
        case model_name
          when :attribute then "setting"
          when :component then "install_component"
          when :node then "create_node"
          else raise Error::NotImplemented.new("when object type is #{object_model_name}")
        end 
      end

      #TODO: ### may deprecate below

      public

      def self.converge_state_changes(node_idhs)
        sample_idh = node_idhs.first()
        sp_hash = {
          cols: [:id,:datacenter_datacenter_id,:components]
        }
        new_item_hashes = Model.get_objs_in_set(node_idhs,sp_hash).map do |r|
          {
            new_item: r[:component].id_handle(), 
            parent: sample_idh.createIDH(model_name: :datacenter, id: r[:datacenter_datacenter_id]),
            type: "converge_component"
          }
        end
        pending_change_items(new_item_hashes)
      end
    end
  end
end
