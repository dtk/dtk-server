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

    attr_accessor :save_flag

    def self.create_from_input(input_hash,c)
      raise Error.new("search object is ill-formed") unless is_valid?(input_hash)
      sp = nil_if_empty(input_hash["search_pattern"])
      hash = {
        :id => nil_if_empty(input_hash["id"]),
        :display_name => nil_if_empty(input_hash["name"]),
        :search_pattern => sp ? SearchPattern.new(sp) : nil
      }
      ret = SearchObject.new(hash,c)
      ret.save_flag = input_hash["save"]
      ret
    end

    def should_save?
      return nil unless search_pattern
      return true if save_flag
      not search_pattern.is_default_view?()
    end

    def save()
      if @id_handle
        self.class.update_from_hash_assignments(@id_handle,self)
      else
        #TODO: consider putting searches at top
        parent_id_handle = IDHandle[:c => @c,:uri => "/library/test", :model_name => :library] #TODO: stub
        hash_assignments = self[:display_name] ? self : self.merge(:display_name => "search_object")
        ref = hash_assignments[:display_name]
        create_hash = {:search_object => {ref => hash_assignments}}
        new_id = self.class.create_from_hash(parent_id_handle,create_hash).map{|x|x[:id]}.first
        @id_handle = IDHandle[:c => @c, :guid => new_id, :model_name => :search_object]
      end
      id()
    end

    def needs_to_be_retrieved?()
      (id and not search_pattern) ? true : nil
    end

    def retrieve_from_saved_object!()
      raise Error.new("cannot update without an id") unless id()
      saved_object = self.class.get_objects(model_handle,{:id => id()}).first
      raise Error.new("cannot find saved search with id (#{id.to_s})") unless saved_object
      saved_object.each{|k,v| self[k] = k.nil? ? nil : (k == :search_pattern ? SearchPattern.new(v) : v)}
    end

    def self.is_valid?(input_hash)
      #TODO: can do finer grain validation
      (nil_if_empty(input_hash["id"]) or nil_if_empty(input_hash["search_pattern"])) ? true : nil
    end

    def db()
      self.class.db()
    end

    def search_pattern()
      self[:search_pattern]
    end
    
    def create_and_save_list_view_in_cache?(user)
      #TODO: needs refinement
      return nil unless search_pattern
      return nil if search_pattern.is_default_view?()

      view_meta_hash = search_pattern ? search_pattern.create_list_view_meta_hash() : nil
      raise Error.new("cannot create list_view meta hash") unless view_meta_hash
      is_saved_search = true

      raise ErrorNotImplemented.new("when search_pattern.relation is of type #{search_pattern.relation.class}") unless search_pattern.relation.kind_of?(Symbol)
      view = R8Tpl::ViewR8.new(search_pattern.relation,saved_search_ref(),user,is_saved_search,view_meta_hash)
      view.update_cache_for_saved_search?()
    end

    def field_set()
      search_pattern ? search_pattern.field_set() : nil
    end
    def order_by()
      search_pattern ? search_pattern.order_by() : nil
    end
    def paging()
      search_pattern ? search_pattern.paging() : nil
    end

    def id()
      @id_handle ? @id_handle.get_id() : nil
    end
    def name()
      self[:display_name]
    end

    def saved_search_template_name()
      "#{saved_search_model_name()}/#{saved_search_ref()}" if saved_search_model_name() and saved_search_ref()
    end

   private
    def saved_search_model_name()
      :saved_search
    end
    def saved_search_ref()
      id ? "ss-#{id.to_s}" : nil
    end

    def self.nil_if_empty(x)
      (x.respond_to?(:empty?) and x.empty?) ? nil : x
    end
  end
end
