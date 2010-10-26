module XYZ
  class SavedSearch < Model
    set_relation_name(:saved_search,:saved_search)
    def self.up()
      column :search_pattern, :json
      many_to_one :library
      #TODO: for testing
      virtual_column :search_result
       ### virtual column defs
      def search_result()
        #TODO: hacked model handle
        model_handle = ModelHandle.new(@c,:saved_search)
        ds = SQL::DataSetSearchPattern.create_dataset_from_hash(self.class.db,model_handle,self[:search_pattern])
        #TODO: hack because ds.all not working right
        ds ? ds.sequel_ds.all : nil
      end
    end
  end
end
