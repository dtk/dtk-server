require File.expand_path('search_pattern_parser', File.dirname(__FILE__))

module XYZ
  class SearchObject < Model
    set_relation_name(:search,:object)
    def self.up()
      column :search_pattern, :json
      many_to_one :library
    end

    ### virtual column defs
    #helper fns

    def create_dataset()
      SQL::DataSetSearchPattern.create_dataset_from_search_object(self)
    end  

    attr_accessor :should_save

    def self.create_from_input(input_hash,c)
      raise Error.new("search object is ill-formed") unless is_valid?(input_hash)
      hash = {
        :id => input_hash["id"],
        :display_name => input_hash["name"],
        :search_pattern => input_hash["search_pattern"] ? SearchPattern.new(input_hash["search_pattern"]) : nil
      }
      ret = SearchObject.new(hash,c)
      ret.should_save = input_hash["save"]
      ret
    end

    def save?()
      should_save
    end

    def needs_to_be_retrieved?()
      (id and not search_pattern) ? true : nil
    end

    #TODO: some of these fns should be geenric model fns
    def update!()
      raise Error.new("cannot update without an id") unless id()
      saved_object = self.class.get_objects(model_handle,{:id => id()}).first
      raise Error.new("cannot find saved search with id (#{id.to_s})") unless saved_object
      saved_object.each{|k,v| self[k] = k.nil? ? nil : (k == :search_pattern ? SearchPattern.new(v) : v)}
    end

    def self.is_valid?(input_hash)
      #TODO: can do finer grain validation
      (input_hash["id"] or input_hash["search_pattern"]) ? true : nil
    end

    def db()
      self.class.db()
    end

    def search_pattern()
      self[:search_pattern]
    end
    
    def field_set()
      search_pattern ? search_pattern.field_set() : nil
    end
    
   private
    def id()
      @id_handle ? @id_handle.get_id() : nil
    end

    def name()
      self[:display_name]
    end
  end
end
