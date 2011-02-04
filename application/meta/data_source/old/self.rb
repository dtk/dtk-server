#    set_relation_name(:data_source,:data_source)
    class << self
      def up()
        column :ds_name, :varchar, :size => 25 
        column :source_handle, :json
        column :last_collection_timestamp, :timestamp #last time when data source collection completed
        many_to_one :library, :datacenter
        one_to_many :data_source_entry
      end
    end

