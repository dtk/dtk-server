
module XYZ
  class Aux
    class Cache < Hash
    end

    class << self
      def benchmark(name,&block)
        require 'benchmark'
        puts "------------- #{name} ----------------"
        ret = nil
        puts Benchmark.measure{ret=block.call}
        puts "---------end: #{name} ----------------\n\n"
        ret
      end

      def ret_key(key_value)
        return nil unless key_value.kind_of?(Hash)
        key_value.keys.first
      end
      def ret_value(key_value)
        return nil unless key_value.kind_of?(Hash)
        key_value.values.first
      end

      def hash_from_file_with_json(file_name)
        return nil unless File.exists?(file_name)
        ret = nil
        File.open(file_name) do |f|
          begin
            json = f.read
          rescue Exception => err
            raise Error.new("error reading file (#{data_file_path}): #{err}")
          end
          begin
            ret = JSON.parse(json)
           rescue Exception => err
            #use pure json to find parsing error
            require 'json/pure'
            begin 
              JSON::Pure::Parser.new(json).parse
             rescue Exception => detailed_err
              raise Error.new("file (#{file_name} has json parsing error: #{detailed_err}")
            end
          end
        end
        ret
      end

      def create_object_slice(hash,slice_keys,opts={})
        ret = Hash.new
        slice_keys.each do |k|
          val = hash[k]
          ret[k] = val if (val or opts[:include_null_cols])
        end
        ret
      end

      def pp_form(obj)
        require 'pp'
        x = ""
        PP.pp obj, x
        x
      end

      def tokenize_bracket_name(x)
        x.split("[").map{|y|y.gsub(/\]/,"")}
      end

      def put_in_bracket_form(token_array)
        if token_array.size == 1
          token_array[0]
        else
          first = token_array.shift
          "#{first}[#{token_array.join("][")}]"
        end
      end


      ## Taken from Sequel
      def camelize(str_x,first_letter_in_uppercase = :upper)
        str = str_x.to_s
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

      def merge_into_json_col!(base,key,update)
        if update.kind_of?(Hash) and base[key].kind_of?(Hash)
          update.each{|k,v|merge_into_json_col!(base[key],k,v)} 
        else
          base[key] = update
        end
      end

      def col_refs_to_keys(hash)
        hash.inject({}){|h,kv|h.merge(kv[0].to_sym => kv[1])}
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
  class Debug
    class << self
      def print_and_ret(x)
        pp x
        x
      end
    end
  end
end

###for more succinctly handling pattern where class exposes methods on an internal object
class Class
  #TODO: consider variant where third argument passed which is lambda indicating how to 
  #transform inputs before applying to interval method var
  def expose_methods_from_internal_object(innervar,methods_to_expose,opts={})
    return expose_methods_with_benchmark(innervar,methods_to_expose,opts) if opts[:benchmark]
    methods_to_expose.each do |m| 
      method_def = 
        if opts[:post_hook]
          "def #{m}(*args);#{opts[:post_hook]}.call(@#{innervar}.#{m}(*args));end"
        else
          "def #{m}(*args);@#{innervar}.#{m}(*args);end"
        end
      class_eval(method_def) 
    end
  end

  #TODO: just for testing; 

  def expose_methods_with_benchmark(innervar,methods_to_expose,opts={})
    b = opts[:benchmark]
    methods_to_expose.each do |m| 
      exec = "@#{innervar}.#{m}(*args)"
      exec = "XYZ::Aux.benchmark('#{m}'){#{exec}}" if b == :all or (b.respond_to?(:include?) and b.include?(m))
      method_def = 
        if opts[:post_hook]
          #TODO: whethether benchmark shoudl include post_hook
          "def #{m}(*args);#{opts[:post_hook]}.call(#{exec});end"
        else
          "def #{m}(*args);#{exec};end"
        end
      class_eval(method_def)
    end
  end

  def expose_all_methods_from_internal_object(innervar)
    method_def = "def method_missing(method,*args);@#{innervar}.send(method,*args);end"  
    class_eval(method_def)
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
   def this_parent_parent_method
     caller[2] =~ /`([^']*)'/ and $1
   end
end

