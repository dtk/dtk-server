module XYZ
  class SavedSearch < Model
    set_relation_name(:saved_search,:saved_search)
    def self.up()
      column :search, :json
      many_to_one :library
    end
  end
end
