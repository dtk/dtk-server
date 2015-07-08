module DTK
  class Clone; class CopyProcessor
    class ForeignKeyInfo
      def initialize(db)
        @info = {}
        @db = db
        @no_fk_processing = false
      end

      def add_id_handles(new_id_handles)
        return if @no_fk_processing
        new_id_handles.each do |idh|
          model_handle_info(idh)[:new_ids] << idh.get_id()
        end
      end

      def shift_foregn_keys
        return if @no_fk_processing
        each_fk do |model_handle, fk_model_name, fk_cols|
          # get (if the set of id mappings for fk_model_name
          id_mappings = get_id_mappings(model_handle,fk_model_name)
          next if id_mappings.empty?
          # TODO: may be more efficient to shift multiple fk cols at same time
          fk_cols.each{|fk_col|shift_foregn_keys_aux(model_handle,fk_col,id_mappings)}
        end
      end

      def add_id_mappings(model_handle,objs_info,opts={})
        return if @no_fk_processing
        @no_fk_processing = avoid_fk_processing?(model_handle,objs_info,opts)
        model_index = model_handle_info(model_handle)
        model_index[:id_mappings] = model_index[:id_mappings]+objs_info.map{|x|Aux::hash_subset(x,[:id,:ancestor_id])}
      end

      def add_foreign_keys(model_handle,field_set)
        return if @no_fk_processing
        # TODO: only putting in once per model; not sure if need to treat instances differently; if not can do this alot more efficiently computing just once
        fks = model_handle_info(model_handle)[:fks]
        # put in foreign keys that are not special keys like ancestor or assembly_id
        omit = Global::ForeignKeyOmissions[model_handle[:model_name]]||[]
        field_set.foreign_key_info().each do |fk,fk_info|
          next if fk == :ancestor_id || omit.include?(fk)
          pointer = fks[fk_info[:foreign_key_rel_type]] ||= []
          pointer << fk unless pointer.include?(fk)
        end
      end

      private

      def avoid_fk_processing?(model_handle,objs_info,opts)
        return false unless opts[:top]
        model_handle[:model_name] != :component || (objs_info.first||{})[:type] != "composite"
      end

      def shift_foregn_keys_aux(model_handle,fk_col,id_mappings)
        model_name = model_handle[:model_name]
        base_fs = Model::FieldSet.opt([:id,{fk_col => :old_key}],model_name)
        base_wc = SQL.in(:id,model_handle_info(model_handle)[:new_ids])
        base_ds = Model.get_objects_just_dataset(model_handle,base_wc,base_fs)

        mappping_rows = id_mappings.map{|r| {fk_col => r[:id], :old_key => r[:ancestor_id]}}
        mapping_ds = SQL::ArrayDataset.create(@db,mappping_rows,model_handle.createMH(model_name: :mappings))
        select_ds = base_ds.join_table(:inner,mapping_ds,[:old_key])

        field_set = Model::FieldSet.new(model_name,[fk_col])
        Model.update_from_select(model_handle,field_set,select_ds)
      end

      def model_handle_info(mh)
        @info[mh[:c]] ||= {}
        @info[mh[:c]][mh[:model_name]] ||= {id_mappings: [], fks: {}, new_ids: []}
      end

      def each_fk(&block)
        @info.each do |c,rest|
          rest.each do |model_name, hash|
            hash[:fks].each do |fk_model_name, fk_cols|
              block.call(ModelHandle.new(c,model_name),fk_model_name, fk_cols)
            end
          end
        end
      end

      def get_id_mappings(mh,fk_model_name)
        ((@info[mh[:c]]||{})[fk_model_name]||{})[:id_mappings] || []
      end
    end
  end; end
end
