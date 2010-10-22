module XYZ
  module SQL
    class DataSetSearchPattern < Dataset
      def initialize(db,model_handle,json_search)
        sequel_ds = ret_sequel_ds_from_json(db.dataset(),json_search)
        super(model_handle,sequel_ds)
      end
      def ret_sequel_ds_from_json(ds,json_search)
        ret_sequel_ds_from_hash!(ds,SON.parse(json_search))
      end
      private
      def ret_sequel_ds_from_hash!(ds,hash_dataset)
        ds = ret_sequel_ds_with_relation!(ds,hash_dataset)
        return nil unless ds
      end

      def ret_sequel_ds_with_relation(ds,hash_dataset)
        relation_str = find(:relation,hash_dataset)
        return nil unless relation_str
        model_name = relation_str.to_sym
        sql_tbl_name = DB.self.sequel_table_name(model_name)
        unless sql_tbl_name
          Log.error("illegal relation given #{relation_str}") 
          retrun nil
        end
        ds.from(sql_tbl_name)
      end

      def find(type,hash_dataset)
        key_val = hash_dataset.find{|obj|obj.its_key() == type}
        key_val ? its_value(key_val) : nil
      end

      def its_key(key_value)
        return nil unless key_value.kind_of?(Hash)
        key_value.keys.first.to_sym
      end
      def its_value(key_value)
        return nil unless key_value.kind_of?(Hash)
        key_value.values.first
      end
    end
  end
end
