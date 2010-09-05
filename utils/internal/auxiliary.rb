module XYZ
  ##relies on Sequel overwriting ~ | and &
  module SQL
    def self.not(x)
      return nil if x.nil?
      ~x
    end
    def self.or(*args)
      ret = nil
      args.reverse.each{|x|ret = or_aux(x,ret)}
      ret
    end
    def self.and(*args)
      ret = nil
      args.reverse.each{|x|ret = and_aux(x,ret)}
      ret
    end
    # returns [x_with_parent_id_removed,parent_id] or [x,nil] if parent_id not in list
    #does not treat parent_id neseted in logical expression
    def self.find_and_remove_parent_id(x)
      return [x,nil] unless x.kind_of?(Hash)
      return [x,nil] unless x.has_key?(:parent_id)
      y = x.dup
      parent_id = y.delete(:parent_id)
      [y,parent_id]
    end

   private
    def self.or_aux(x,y)
      return y if x.nil? or (x.kind_of?(Hash) and x.empty?)
      return x if y.nil? or (y.kind_of?(Hash) and y.empty?)
      x | y
    end
    def self.and_aux(x,y)
      return y if x.nil? or (x.kind_of?(Hash) and x.empty?)
      return x if y.nil? or (y.kind_of?(Hash) and y.empty?)
      x & y
    end
  end  

  class Aux
    class << self
      def pp_form(obj)
        require 'pp'
        x = ""
        PP.pp obj, x
        x
      end

      ## Taken from Sequel
      def camelize(str,first_letter_in_uppercase = :upper)
        s = str.gsub(/\/(.?)/){|x| "::#{x[-1..-1].upcase unless x == '/'}"}.gsub(/(^|_)(.)/){|x| x[-1..-1].upcase}
       s[0...1] = s[0...1].downcase unless first_letter_in_uppercase == :upper
       s
      end

      def underscore(str)
        str.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
      end
      def demodulize(str)
        str.gsub(/^.*::/, '')
      end
     
      def without_keys(hash,array_with_keys_to_remove)
        hash.reject{|k,v| array_with_keys_to_remove.include?(k)}
      end

      #object or nesting is scalar, Hash or Array
      def objects_equal?(x,y)
        if x.nil?
          y.nil?
        elsif y.nil?
          nil
        elsif x.kind_of?(Hash)
          return nil unless y.kind_of?(Hash)
          return nil unless x.size == y.size
          x.each{|k,v|
            return nil unless objects_equal?(v,y[k])
          }
          true
        elsif x.kind_of?(Array)
          return nil unless y.kind_of?(Array)
          return nil unless x.size == y.size
          for i in 0..x.size
            return nil unless objects_equal?(x[i],y[i])
          end
          true
        else
          return nil if y.kind_of?(Hash) or y.kind_of?(Array)
          x == y
        end
      end

      # fn below used to make sure that all hash keys  are symbols
      #TBD: make a more efficient one that just updates hash just where appropriate
      def ret_hash_assignments(hash)
        ret = {}
        hash.each_pair{ |k,v|
          ret[k.to_sym] = v.kind_of?(Hash) ? ret_hash_assignments(v) : v
        }
        ret
      end
      def marshal_to_wire(obj)
        ::Marshal.dump(obj)
      end
      def unmarshal_from_wire(data)
        ::Marshal.load(data)
      end
      # changes all keys to ":" form
      def convert_to_hash_symbol_form(json_or_scalar)
        begin
          convert_to_symbol_form_aux(JSON.parse(json_or_scalar))
         rescue
          #primarily to handle scalars
          json_or_scalar
        end
      end

      def convert_to_symbol_form_aux(item)
        if item.kind_of?(Array)
          item.map{|x|convert_to_symbol_form_aux(x)} 
        elsif item.kind_of?(Hash)
          ret = {}
          item.each{|k,v|ret[k.to_sym] = convert_to_symbol_form_aux(v)}
          ret
        else
          item
        end
      end
    end
  end
end

#for being able to determine the method name in the function call
module Kernel
private
   def this_method
     caller[0] =~ /`([^']*)'/ and $1
   end
   def this_parent_method
     caller[1] =~ /`([^']*)'/ and $1
   end
end

###for more succinctly handling pattern where class exposes methods on an internal object
#TODO: must be careful in not aserted this twice for same class also cant be used for two different internal vars
class Class
  def expose_all_methods_from_internal_object(innervar)
    method_def = "def method_missing(method,*args);@#{innervar}.send(method,*args);end"  
    class_eval(method_def)
  end

#TODO: reqwrite to instead of using method missing, explicitly add methods
#this will also solve problem cited above (i.e., cant have two assignments for same class
#TODO: consider variant where third argument passed which is lambda indicating how to transform inputs before applying to interval method var
  def expose_methods_from_internal_object(innervar,methods_to_expose)
    method_str = "[#{methods_to_expose.map{|x|":#{x}"}.join(",")}]"
    no_method_err_str = 'NoMethodError.new("#{self.class.to_s}##{method}")'
    method_def = "def method_missing(method,*args);raise #{no_method_err_str} unless #{method_str}.include?(method);@#{innervar}.send(method,*args);end"  
    class_eval(method_def)
  end
end

 


