require 'rubygems'
require 'pp'
class_name = 'foo'.capitalize
#klass = Object.const_set(class_name,Class.new)
class Top 
  def test()
    pp :works
  end
end

class Service
  def test2()
    pp :test2
  end
end
#klass = Object.const_set(class_name,Class.new)
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
      }
}
      def camelize(str_x,first_letter_in_uppercase = :upper)
        str = str_x.to_s
        s = str.gsub(/\/(.?)/){|x| "::#{x[-1..-1].upcase unless x == '/'}"}.gsub(/(^|_)(.)/){|x| x[-1..-1].upcase}
       s[0...1] = s[0...1].downcase unless first_letter_in_uppercase == :upper
       s
      end
      
      def all_keys(x)
        return Array.new unless x.kind_of?(Hash)
        x.keys + x.values.map{|el|all_keys(el)}.flatten
      end

      all_keys(TypeHierarchy).each do |key|
        Object.const_set(camelize(key),Top)
      end
Perl.new.test()
Service.new.test2()
