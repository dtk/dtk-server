require File.expand_path('search_pattern_parser', File.dirname(__FILE__))

module XYZ
  class SearchObject < Model
    def json_search_pattern
      search_pattern ? JSON.generate(search_pattern) : nil
    end

    def create_dataset
      SQL::DataSetSearchPattern.create_dataset_from_search_object(self)
    end

    attr_accessor :save_flag, :source

    def self.create_from_input_hash(input_hash, source, c)
      fail Error.new('search object is ill-formed') unless is_valid?(input_hash)
      sp = nil_if_empty(input_hash['search_pattern'])
      hash = {
        id: nil_if_empty(input_hash['id']),
        display_name: nil_if_empty(input_hash['display_name']),
        search_pattern: sp ? SearchPattern.create(sp) : nil
      }
      ret = SearchObject.new(hash, c)
      ret.save_flag = input_hash['save']
      ret.source = source
      ret
    end

    def self.create_from_field_set(field_set, c, filter = nil)
      sp = { relation: field_set.model_name, columns: field_set.cols }
      sp.merge!(filter: filter) if filter
      hash = { search_pattern: SearchPattern.create(sp) }
      SearchObject.new(hash, c)
    end

    def json
      sp = self[:search_pattern]

      # TODO: this is for case when get back search objects from get objects; remove when process uniformally meaning non null will always be serach pattern object
      hash_for_json_sp = sp ? (sp.is_a?(SearchPattern) ? sp.hash_for_json_generate() : sp) : nil

      hash_for_json_generate = {
        'display_name' => self[:display_name],
        'relation' => self[:relation],
        'id' => self[:id],
        'search_pattern' => hash_for_json_sp
      }
      JSON.generate(hash_for_json_generate)
    end

    def should_save?
      return nil unless search_pattern
      return true if save_flag
      not(search_pattern.is_default_view?() or source == :action_set or source == :node_group)
    end

    # Remove
    #     def save_list_view_in_cache?(user)
    #       return nil unless should_save?
    #       view_meta_hash = search_pattern ? search_pattern.create_list_view_meta_hash() : nil
    #       raise Error.new("cannot create list_view meta hash") unless view_meta_hash
    #       is_saved_search = true
    #
    #       raise Error::NotImplemented.new("when search_pattern.relation is of type #{search_pattern.relation.class}") unless search_pattern.relation.kind_of?(Symbol)
    #       view = R8Tpl::ViewR8.new(search_pattern.relation,saved_search_ref(),user,is_saved_search,view_meta_hash)
    #       # TODO: this necssarily updates if reaches here; more sophistiacted woudl update cache file only if need to
    #       view.update_cache_for_saved_search()
    #     end
    #
    #     def self.save_list_view_in_cache(id,hash_assignments,user)
    #       search_pattern_json = hash_assignments[:search_pattern]
    #       return nil unless search_pattern_json
    #       search_pattern = SearchPattern.create(JSON.parse(search_pattern_json))
    #       view_meta_hash = search_pattern.create_list_view_meta_hash()
    #       return nil unless search_pattern.relation
    #       is_saved_search = true
    #       view = R8Tpl::ViewR8.new(search_pattern.relation,saved_search_ref(id),user,is_saved_search,view_meta_hash)
    #       view.update_cache_for_saved_search()
    #     end

    def save(model_handle)
      search_pattern_db =  search_pattern.ret_form_for_db()
      relation_db = (search_pattern || {})[:relation] ? search_pattern[:relation].to_s : nil
      if @id_handle
        fail Error.new('saved search cannot be updated unless there is a name or search a pattern') unless search_pattern or name
        hash_assignments = {}
        hash_assignments[:display_name] = name if name
        hash_assignments[:search_pattern] =  search_pattern_db if search_pattern_db
        hash_assignments[:relation] = relation_db if relation_db
        self.class.update_from_hash_assignments(@id_handle, hash_assignments)
      else
        fail Error.new('saved search cannot be created if search_pattern or relation does not exist') unless search_pattern_db and relation_db
        factory_idh = model_handle.createIDH(uri: '/search_object', is_factory: true)
        hash_assignments = {
          display_name: name || 'search_object',
          search_pattern: search_pattern_db,
          relation: relation_db
        }
        ref = hash_assignments[:display_name]
        create_hash = { ref => hash_assignments }
        new_id = Model.create_from_hash(factory_idh, create_hash).map { |x| x[:id] }.first
        @id_handle = IDHandle[c: @c, id: new_id, model_name: :search_object]
      end
      id()
    end

    def needs_to_be_retrieved?
      (id and not search_pattern) ? true : nil
    end

    def retrieve_from_saved_object!
      fail Error.new('cannot update without an id') unless id()
      saved_object = self.class.get_objects(model_handle, { id: id() }).first
      fail Error.new("cannot find saved search with id (#{id})") unless saved_object
      saved_object.each do |k, v|
        next unless v
        self[k] = k == :search_pattern ? SearchPattern.create(v) : v
      end
    end

    def self.is_valid?(input_hash)
      # TODO: can do finer grain validation
      (nil_if_empty(input_hash['id']) or nil_if_empty(input_hash['search_pattern'])) ? true : nil
    end

    def db
      self.class.db()
    end

    def search_pattern
      self[:search_pattern]
    end

    def related_remote_column_info(vcol_sql_fns = nil)
      search_pattern ? search_pattern.related_remote_column_info(vcol_sql_fns) : nil
    end

    def field_set
      search_pattern ? search_pattern.field_set() : nil
    end

    def order_by
      search_pattern ? search_pattern.order_by() : nil
    end

    def paging
      search_pattern ? search_pattern.paging() : nil
    end

    def id
      @id_handle ? @id_handle.get_id() : nil
    end

    def name
      self[:display_name]
    end

    def saved_search_template_name
      "#{saved_search_model_name()}/#{saved_search_ref()}" if saved_search_model_name() and saved_search_ref()
    end

    private

    def saved_search_model_name
      :saved_search
    end
    def self.saved_search_ref(id)
      id ? "ss-#{id}" : nil
    end
    def saved_search_ref
      self.class.saved_search_ref(id)
    end

    def self.nil_if_empty(x)
      (x.respond_to?(:empty?) and x.empty?) ? nil : x
    end
  end
end
