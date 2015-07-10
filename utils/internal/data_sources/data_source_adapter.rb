module XYZ
  module DataSourceAdapterInstanceMixin
    # Should be overwritten if no dsl
    def normalize(ds_hash)
      target_obj = DBUpdateHash.create()
      @ds_object_adapter_class.class_rules.each do |condition, top_level_assign|
        if condition.evaluate_condition(ds_hash)
          top_level_assign.each do |attr, assign|
            process_assignment(target_obj, attr, assign, ds_hash)
          end
        end
      end
      target_obj
    end

    def relative_distinguished_name(ds_hash)
      @ds_object_adapter_class.relative_distinguished_name(ds_hash)
    end

    private

    def load_ds_adapter_class
      rel_path = "#{ds_name()}/#{obj_type()}#{source_obj_type() ? '__' + source_obj_type() : ''}"
      begin
        file_path = File.expand_path(rel_path, File.dirname(__FILE__))
        require file_path
       rescue Exception => e
        raise Error.new("Adapter file (#{file_path}.rb) to process object #{obj_type()} for data source #{ds_name()} #{source_obj_type() ? "(using source object #{source_obj_type()}) " : ''} does not exist") unless File.exist?(file_path + '.rb')
        raise e
      end

      base_class = DSNormalizer.const_get Aux.camelize(ds_name())
      @ds_object_adapter_class = base_class.const_get Aux.camelize("#{obj_type()}#{source_obj_type() ? '_' + source_obj_type() : ''}")
    end

    def normalize_and_update_db(container_id_handle, ds_hash, marked)
      return nil if ds_hash.nil?
      marked << ds_key_value(ds_hash)
      db_update_hash = ret_db_update_hash(container_id_handle, ds_hash)
      Model.input_into_model(container_id_handle, db_update_hash)
    end

    def ret_db_update_hash(_container_id_handle, ds_hash)
      obj = normalize(ds_hash)
      obj[:ds_attributes] = filter_raw_source_objects(ds_hash)
      obj[:ds_key] = ds_key_value(ds_hash)
      obj[:ds_source_obj_type] = source_obj_type() if source_obj_type()
      obj[:data_source] = ds_name()
      ret = DBUpdateHash.create()
      ret[relation_type()][ref(ds_hash)] = obj
      ret.freeze
    end

    def process_assignment(target_obj, attr, assign, ds_hash)
      if assign.is_a?(DSNormalizer::Source)
        target_obj[attr] = assign.apply(ds_hash)
      elsif assign.is_a?(DSNormalizer::Function)
        target_obj[attr] = assign.apply(ds_hash)
      elsif assign.is_a?(DSNormalizer::NestedDefinition)
        target_obj[attr] = assign.normalize(ds_hash, self)
      elsif assign.is_a?(DSNormalizer::ForeignKey)
        process_assignment(target_obj, Object.mark_as_foreign_key(attr, { create_ref_object: true }), assign.arg, ds_hash)
      elsif assign.is_a?(Hash)
        # TBD: use of paranthesis below may be needed because of possible Ruby parser bug
        constraints = (assign.is_a?(DBUpdateHash) ? assign.constraints : nil)
        target_obj[attr].set_constraints(constraints) if constraints
        if assign.empty?
          # include empty hash if there are constraints associated with it (this wil serve to delet all
          # its peers; only including this conditionally is for optimization
          # dont overwrite will null if  target_obj[attr] already has a value
          if constraints and not target_obj.key?(attr)
            target_obj[attr] = assign
          end
        else
          assign.each do |nested_attr, nested_assign|
            process_assignment(target_obj[attr], nested_attr, nested_assign, ds_hash)
          end
        end
      else
       target_obj[attr] = assign
      end
    end

    # only consider complete and thus perform deletes if source is marked as compleet as designated by
    # hash_completeness_info and source is golden store
    def delete_unmarked(container_id_handle, marked, hash_completeness_info)
      return nil unless hash_completeness_info.is_complete?()
      return nil unless ds_is_golden_store()
      constraints = hash_completeness_info.constraints
      marked_disjunction = nil
      marked.each do |ds_key|
        marked_disjunction = SQL.or(marked_disjunction, { ds_key: ds_key })
      end
      where_clause = SQL.not(marked_disjunction)
      where_clause = SQL.and(where_clause, constraints) unless constraints.empty?
      Object.delete_instances_wrt_parent(relation_type(), container_id_handle, where_clause)
    end

    def relation_type(obj_type_override = nil)
      (obj_type_override || obj_type()).to_sym
    end

    def ds_key_value(ds_hash)
      relative_unique_key = @ds_object_adapter_class.unique_keys(ds_hash)
      qualified_key(relative_unique_key)
    end

    def filter_raw_source_objects(ds_hash)
      @ds_object_adapter_class.filter_raw_source_objects(ds_hash)
    end

    def qualified_key(relative_unique_key, ds_name_override = nil)
      ([(ds_name_override || ds_name()).to_sym] + relative_unique_key).inspect
    end

    def ref(ds_hash)
      relative_distinguished_name(ds_hash)
    end
  end
end
