module XYZ
  class SearchObject < Model
    set_relation_name(:search,:object)
    def self.up()
      column :search_pattern, :json
      many_to_one :library
      #TODO: for testing
      virtual_column :search_result
    end

    ### virtual column defs

    def search_result()
      #TODO: hacked model handle
      ds = SQL::DataSetSearchPattern.create_dataset_from_hash(self.class.db,model_handle,self[:search_pattern])
      #TODO: hack because ds.all not working right
      ds ? ds.sequel_ds.all : nil
    end  

    #helper fns
    attr_accessor :should_save

    def self.create_from_input(input_hash,c)
      raise Error.new("search object is ill-formed") unless is_valid?(input_hash)
      hash = {
        :id => input_hash["id"],
        :display_name => input_hash["name"],
        :search_pattern => input_hash["search_pattern"]
      }
      ret = SearchObject.new(hash,c,:search_pattern)
      ret.should_save = input_hash["save"]
      ret
    end

    #TODO: some of these fns should be geenric model fns
    def save?()
      should_save
    end

    def needs_to_be_retrieved?()
      (id and not search_pattern) ? true : nil
    end

    def update!()
      raise Error.new("cannot update without an id") unless id()
      saved_object = self.class.get_objects(model_handle,{:id => id()})
      raise Error.new("cannot fidn saved search with id (#{search_object.id.to_s}") unless saved_object
    end

    def self.is_valid?(input_hash)
      #TODO: can do finer grain validation
      (input_hash["id"] or input_hash["search_pattern"]) ? true : nil
    end

   private
    def id()
      @id_handle ? @id_handle.get_id() : nil
    end

    def name()
      self[:display_name]
    end
    def search_pattern()
      self[:search_pattern]
    end
  end
end
