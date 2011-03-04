module XYZ
  class ComponentBasicType
   private
    TypeHierarchy = {
      :service => {
        :app_server=>{},
        :db_server => {
          :postgres_db_server=>{},
          :mysql_db_server=>{},
          :oracle_db_server=>{},
        },
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
      },

      :database => {
        :postgres_db=>{},
        :mysql_db=>{},
        :oracle_db=>{},
      }, 

    }
  end
end
