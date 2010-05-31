module XYZ
  class DiscoveryContext < Model
    set_relation_name(:discovery,:context)
    class << self
      def up()
        column :source_handle, :json
        column :update_policy, :json #indicates whether 
        column :objects_location, :json
        many_to_one :library,:project
      end
    end
  end
end
