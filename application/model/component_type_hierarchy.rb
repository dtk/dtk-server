module XYZ
  class ComponentTypeHierarchy
    def self.basic_type(specific_type)
      ret_basic_type[specific_type.to_sym]
    end
   private
    def self.ret_basic_type()
      @@basic_type ||= TypeHierarchy.inject({}){|h,kv|h.merge(ret_basic_type_aux(kv[0],kv[1]))}
    end

    def self.ret_basic_type_aux(basic_type,hier)
      keys_in_hierarchy(hier).inject({}){|h,x| h.merge(x => basic_type)}
    end

    def self.keys_in_hierarchy(hier)
      hier.inject([]){|a,kv|a + [kv[0]] + keys_in_hierarchy(kv[1])}
    end

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
end
