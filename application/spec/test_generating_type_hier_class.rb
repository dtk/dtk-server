require 'rubygems'
require 'pp'

# klass = Object.const_set(class_name,Class.new)

# taken from http://www.ruby-forum.com/topic/163430
=begin
class Class
  def inherited other
    super if defined? super
  ensure
    ( @subclasses ||= [] ).push(other).uniq!
  end

  def subclasses
    @subclasses ||= []
    @subclasses.inject( [] ) do |list, subclass|
      list.push(subclass, *subclass.subclasses)
    end
  end
end
=end



class Top 
  def test()
    pp :works
  end
  def self.inherited(sub)
    # adapted from  http://www.ruby-forum.com/topic/163430 
    (@subclasses ||= Array.new).push(sub).uniq!
  end

  def self.subclasses()
    @subclasses
  end
end

class Service < Top
  def test2()
    pp :test2
  end
end
class Application < Top
end
Service.new.test2()

# klass = Object.const_set(class_name,Class.new)
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

      existing_subclass_names = Top.subclasses.map{|x|x.to_s}
      all_keys(TypeHierarchy).each do |key|
        klass_name = camelize(key)
        next if existing_subclass_names.include?(klass_name)
        Object.const_set(klass_name,Class.new(Top))
      end
Perl.new.test()
Service.new.test2()
