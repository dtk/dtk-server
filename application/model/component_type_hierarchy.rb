module XYZ
  module TypeHierarchyDefMixin
    TypeHierarchy = {
      service: {
        app_server: {},
        web_server: {},
        db_server: {
          postgres_db_server: {},
          mysql_db_server: {},
          oracle_db_server: {}
        },
        monitoring_server: {},
        monitoring_agent: {},
        msg_bus: {},
        memory_cache: {},
        load_balancer: {},
        firewall: {}
      },

      language: {
        ruby: {},
        php: {},
        perl: {},
        javascript: {},
        java: {},
        clojure: {}
      },

      application: {
        java_app: {
          java_spring: {}
        },
        ruby_app: {
          ruby_rails: {},
          ruby_ramaze: {},
          ruby_sinatra: {}
        },
        php_app: {}
      },

      extension: {},

      database: {
        postgres_db: {},
        mysql_db: {},
        oracle_db: {}
      },

      user: {}
    }
    # TODO: stub implementation
    # given basic type give lsits of link_def_types
    TypeHierarchyPossLinkDefs = {
      application: [
        :database
      ]
    }
  end
  class ComponentTypeHierarchy
    include TypeHierarchyDefMixin

    # TODO: stub; only uses one level; not hirerarchical structure
    def self.possible_link_defs(component)
      ret = []
      basic_type = component.update_object!(:basic_type)[:basic_type]
      return ret unless basic_type
      TypeHierarchyPossLinkDefs[basic_type.to_sym] || []
    end

    def self.basic_type(specific_type)
      ret_basic_type[specific_type.to_sym]
    end

    def self.include?(type)
      type && specific_types.include?(type.to_sym)
    end

    private

    # adapted from  http://www.ruby-forum.com/topic/163430
    def self.inherited(sub)
      return if sub.to_s =~ /^#<Class/ #HACK: to get rid of anonymous classes
      add_to_subclass(sub)
    end

    def self.add_to_subclass(sub)
      subclass_name = Aux::demodulize(sub.to_s)
      (@subclass_names ||= []).push(subclass_name).uniq!
    end
    def self.subclass_names
      @subclass_names
    end

    def self.ret_basic_type
      @basic_type ||= TypeHierarchy.inject({}) { |h, kv| h.merge(ret_basic_type_aux(kv[0], kv[1])) }
    end

    def self.ret_basic_type_aux(basic_type, hier)
      keys_in_hierarchy(hier).inject({}) { |h, x| h.merge(x => basic_type) }
    end

    def self.keys_in_hierarchy(hier)
      hier.inject([]) { |a, kv| a + [kv[0]] + keys_in_hierarchy(kv[1]) }
    end

    def self.find_hierarchy_under_key(key, hier = TypeHierarchy)
      return nil if hier.empty?
      return hier[key] if hier[key]
      hier.values.each do |child|
        ret = find_hierarchy_under_key(key, child)
        return ret if ret
      end
      nil
    end

    def self.keys_under_subtype(subtype)
      subtype_hier = find_hierarchy_under_key(subtype)
      subtype_hier ? keys_in_hierarchy(subtype_hier) : nil
    end

    def self.key_associated_with_class
      Aux.underscore(Aux.demodulize(self.to_s)).to_sym
    end

    def self.specific_types
      return @specific_types if @specific_types
      key = key_associated_with_class()
      @specific_types = [key] + keys_under_subtype(key)
    end
  end

  module ComponentType
    def self.ret_class(type)
      klass_name = Aux::camelize(type.to_s)
      return nil unless ComponentTypeHierarchy.subclass_names().include?(klass_name)
      const_get(klass_name)
    end

    # TODO: intent is to be able to add custom classes
    class DbServer < ComponentTypeHierarchy
    end
    class Application < ComponentTypeHierarchy
    end

    # dynamically create all other classes not explicitly defined
    def self.all_keys(x)
      return [] unless x.is_a?(Hash)
      x.keys + x.values.map { |el| all_keys(el) }.flatten
    end
    existing_subclass_names = ComponentTypeHierarchy.subclass_names()
    include TypeHierarchyDefMixin
    all_keys(TypeHierarchy).each do |key|
      klass_name = Aux::camelize(key)
      unless existing_subclass_names.include?(klass_name)
        ComponentTypeHierarchy.add_to_subclass(const_set(klass_name, Class.new(ComponentTypeHierarchy)))
      end
    end
  end
end
