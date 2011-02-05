#    set_relation_name(:search,:object)
    def self.up()
      column :search_pattern, :json
      column :relation, :varchar, :size => 25
      many_to_one :library
    end
