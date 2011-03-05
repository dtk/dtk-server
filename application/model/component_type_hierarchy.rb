module XYZ
  module TypeHierarchyDefMixin
    TypeHierarchy = {
      :service => {
        :app_server=>{},
        :web_server=>{},
        :db_server => {
          :postgres_db_server=>{},
          :mysql_db_server=>{},
          :oracle_db_server=>{},
        },
        :monitoring_server=>{},
        :monitoring_agent=>{},
        :msg_bus=>{},
        :memory_cache=>{},
        :load_balancer=>{},
        :firewall=>{},
      },

      :language => {
        :ruby=>{},
        :php=>{},
        :perl=>{},
        :javascript=>{},
        :java=>{},
        :clojure=>{},
      },

      :application => {
        :java_app => {
          :java_spring=>{},
        },
        :ruby_app => {
          :ruby_rails=>{},
          :ruby_ramaze=>{},
          :ruby_sinatra=>{},
        },
        :php_app => {},
      },

      :extension => {},

      :database => {
        :postgres_db=>{},
        :mysql_db=>{},
        :oracle_db=>{},
      }, 

      :user => {}
    }
  end
  class ComponentTypeHierarchy
    include TypeHierarchyDefMixin
    def self.basic_type(specific_type)
      ret_basic_type[specific_type.to_sym]
    end

    def self.include?(component)
      specific_types.include?(component[:most_specific_type])
    end

   private
    def self.ret_basic_type()
      @basic_type ||= TypeHierarchy.inject({}){|h,kv|h.merge(ret_basic_type_aux(kv[0],kv[1]))}
    end

    def self.ret_basic_type_aux(basic_type,hier)
      keys_in_hierarchy(hier).inject({}){|h,x| h.merge(x => basic_type)}
    end

    def self.keys_in_hierarchy(hier)
      hier.inject([]){|a,kv|a + [kv[0]] + keys_in_hierarchy(kv[1])}
    end
    
    def self.find_hierarchy_under_key(key,hier=TypeHierarchy)
      return nil if hier.empty?
      return hier[key] if hier[key]
      hier.values.each do |child|
        ret = find_hierarchy_under_key(key,child)
        return ret if ret
      end
      nil
    end

    def self.keys_under_subtype(subtype)
      subtype_hier = find_hierarchy_under_key(subtype)
      subtype_hier ? keys_in_hierarchy(subtype_hier) : nil
    end

    def self.key_associated_with_class()
      Aux.underscore(Aux.demodulize(self.to_s)).to_sym
    end

    def self.specific_types()
      return @specific_types if @specific_types
      key = key_associated_with_class()
      @specific_types = [key.to_s] + keys_under_subtype(key).map{|x|x.to_s}
    end
  end

  module ComponentType
    class DbServer < ComponentTypeHierarchy
    end
    class Application < ComponentTypeHierarchy
    end
  end
end
