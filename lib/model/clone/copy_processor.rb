module DTK
  class Clone
    class CopyProcessor
      r8_nested_require('copy_processor', 'output')
      r8_nested_require('copy_processor', 'assembly')
      r8_nested_require('copy_processor', 'foreign_key_info')

      def self.create(target_obj, source_obj, opts = {})
        if source_obj.is_assembly?
          Assembly.new(target_obj, source_obj, opts)
        else
          new(source_obj, opts)
        end
      end
      def initialize(source_obj, opts = {})
        @db = source_obj.class.db
        @fk_info = ForeignKeyInfo.new(@db)
        @model_name = source_obj.model_name()
        @ret = Output.new(source_obj, opts)
        @include_list = opts[:include_list]
      end
      private :initialize

      # copy part of clone
      # targets is a list of id_handles, each with same model_name
      def clone_copy_top_level(source_id_handle_x, targets, recursive_override_attrs = {})
        return @ret if targets.empty?
        source_model_name = Model.concrete_model_name(source_id_handle_x[:model_name])
        source_id_handle = source_id_handle_x.createIDH(model_name: source_model_name)

        source_model_handle = source_id_handle.createMH()
        source_parent_id_col = source_model_handle.parent_id_field_name()

        # all targets will have same model handle
        sample_target =  targets.first
        target_parent_mh = sample_target.createMH()
        target_mh = target_parent_mh.create_childMH(source_model_name)

        target_parent_id_col = target_mh.parent_id_field_name()
        targets_rows = targets.map { |id_handle| { target_parent_id_col => id_handle.get_id() } }
        targets_ds = SQL::ArrayDataset.create(db, targets_rows, ModelHandle.new(source_id_handle[:c], :target))

        source_wc = { id: source_id_handle.get_id() }

        remove_cols = (source_parent_id_col == target_parent_id_col ? [:id, :local_id] : [:id, :local_id, source_parent_id_col])
        field_set_to_copy = Model::FieldSet.all_real(source_model_name).with_removed_cols(*remove_cols)
        fk_info.add_foreign_keys(source_model_handle, field_set_to_copy)
        source_fs = Model::FieldSet.opt(field_set_to_copy.with_removed_cols(target_parent_id_col))
        source_ds = Model.get_objects_just_dataset(source_model_handle, source_wc, source_fs)

        select_ds = targets_ds.join_table(:inner, source_ds)

        # process overrides
        override_attrs = ret_real_columns(source_model_handle, recursive_override_attrs)
        override_attrs = add_to_overrides_null_other_parents(override_attrs, target_mh[:model_name], target_parent_id_col)
        create_override_attrs = override_attrs.merge(ancestor_id: source_id_handle.get_id())

        new_objs_info = Model.create_from_select(target_mh, field_set_to_copy, select_ds, create_override_attrs, create_opts_for_top())
        return @ret if new_objs_info.empty?
        new_id_handles = @ret.set_new_objects!(new_objs_info, target_mh)
        fk_info.add_id_mappings(source_model_handle, new_objs_info, top: true)

        fk_info.add_id_handles(new_id_handles) #TODO: may be more efficient adding only id handles assciated with foreign keys

        # iterate over all nested objects which includes children object plus, for example, components for composite components
        get_nested_objects_top_level(source_model_handle, target_parent_mh, new_objs_info, recursive_override_attrs) do |child_context|
          clone_copy_child_objects(child_context)
        end
        fk_info.shift_foregn_keys()
        @ret
      end

      def get_nested_objects_top_level(model_handle, _target_parent_mh, objs_info, recursive_override_attrs, &block)
        opts_generate = {}
        if @include_list
          opts_generate.merge!(include_list: @include_list)
        end

        ChildContext.generate(self, model_handle, objs_info, recursive_override_attrs, opts_generate, &block)
      end

      def output
        @ret
      end

      # optionally overwritten
      def service_add_on_proc?
        nil
      end

      def shift_foregn_keys
        fk_info.shift_foregn_keys()
      end

      def clone_copy_child_objects(child_context, level = 1)
        child_context.clone_copy_child_objects(self, level)
        @ret
      end

      def add_new_children_objects(new_objs_info, child_model_handle, clone_par_col, level)
        @ret.add_new_children_objects(new_objs_info, child_model_handle, clone_par_col, level)
      end

      def add_to_overrides_null_other_parents(overrides, model_name, selected_par_id_col)
        many_to_one = DB_REL_DEF[model_name][:many_to_one] || []
        many_to_one.inject(overrides) do |ret_hash, par_mn|
          par_id_col = DB.parent_field(par_mn, model_name)
          if selected_par_id_col == par_id_col || overrides.key?(par_id_col)
            ret_hash
          else
            ret_hash.merge(par_id_col => SQL::ColRef.null_id)
          end
        end
      end

      def child_context_lib_assembly_top_level(id_handles, target_idh, existing_override_attrs = {})
        # TODO: push this into ChildContext.create_from_hash
        # assuming all id_handles have same model_handle
        sample_idh = id_handles.first
        model_name = sample_idh[:model_name]
        # so model_handle gets auth context from target_idh
        model_handle = target_idh.create_childMH(model_name)

        par_id_col = DB.parent_field(target_idh[:model_name], model_name)
        override_attrs = add_to_overrides_null_other_parents(existing_override_attrs, model_name, par_id_col)
        override_attrs.merge!(par_id_col => target_idh.get_id())

        ret_sql_cols = [:ancestor_id]
        case model_name
         when :node then ret_sql_cols << :external_ref
        end
        create_opts = { duplicate_refs: :allow, returning_sql_cols: ret_sql_cols }
        parent_rels = id_handles.map { |idh| { old_par_id: idh.get_id() } }

        ChildContext.create_from_hash(self, model_handle: model_handle, clone_par_col: :id, parent_rels: parent_rels, override_attrs: override_attrs, create_opts: create_opts)
      end

      def add_id_handle(id_handle)
        @ret.add_id_handle(id_handle)
      end

      def ret_child_override_attrs(child_model_handle, recursive_override_attrs)
        recursive_override_attrs[(child_model_handle[:model_name])] || {}
      end

      attr_reader :db, :fk_info, :model_name

      def ret_real_columns(model_handle, recursive_override_attrs)
        fs = Model::FieldSet.all_real(model_handle[:model_name])
        recursive_override_attrs.reject { |k, _v| not fs.include_col?(k) }
      end

      def cloning_assembly?
        nil
      end

      def clone_direction
        nil
      end

      private

      def create_opts_for_top
        dups_allowed_for_cmp = true #TODO: stub

        returning_sql_cols = [:ancestor_id]
        # TODO" may make what are returning sql columns methods in model classes liek do for clone post copy
        case model_name
         when :component then returning_sql_cols << :type
        end

        (@ret.ret_new_obj_with_cols || {}).each { |col| returning_sql_cols << col unless returning_sql_cols.include?(col) }
        { duplicate_refs: dups_allowed_for_cmp ? :allow : :prune_duplicates, returning_sql_cols: returning_sql_cols }
      end
    end
  end
end
