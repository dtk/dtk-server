require 'set'
module DTK
  class Aux
    r8_require('yaml_helper')

    module CommonClassMixin
      def private_instance_method(class_name)
        class_eval("def private__#{class_name}(*args,&block);#{class_name}(*args,&block);end")
      end
    end

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

      # for hashs and arrays
      def deep_copy(obj)
        if obj.kind_of?(Hash)
          obj.inject({}){|h,kv|h.merge(kv[0] => deep_copy(kv[1]))}
        elsif obj.kind_of?(Array)
          obj.map{|el|deep_copy(el)}
        else
          obj
        end
      end

      def platform_is_linux?()
        RUBY_PLATFORM.downcase.include?("linux")
      end
      def platform_is_windows?()
        RUBY_PLATFORM.downcase.include?("mswin") or RUBY_PLATFORM.downcase.include?("mingw")
      end
      def platform()
        RUBY_PLATFORM
      end

      def now_time_stamp()
        SQL.now
        # TODO: change to use app server clock
      end

      def convert_keys_to_symbols(hash)
        hash.keys.inject(Hash.new){|h,k|h.merge(k.to_sym => hash[k])}
      end
      def convert_keys_to_symbols_recursive(obj)
        if obj.kind_of?(Hash)
          obj.keys.inject(Hash.new){|h,k|h.merge(k.to_sym => convert_keys_to_symbols_recursive(obj[k]))}
        elsif obj.kind_of?(Array)
          obj.map{|el|convert_keys_to_symbols_recursive(el)}
        else
          obj
        end
      end
      
      def equal_sets(array1,array2)
        Set.new(array1) == Set.new(array2)
      end

      def has_just_these_keys?(hash,keys)
        Set.new(hash.keys) == Set.new(keys)
      end

      def has_only_these_keys?(hash,keys)
        Set.new(hash.keys).subset?(Set.new(keys))
      end

      def ordered_hash(array_with_hashes)
        array_with_hashes.inject(ActiveSupport::OrderedHash.new) do |h,x|
          h.merge(x.keys.first => x.values.first)
        end
      end

      # key can be symbol or of form {symbol => symbol} 
      def hash_subset(hash,keys,opts={},&block)
        hash_subset_aux(opts[:seed]||Hash.new(),hash,keys,opts,&block)
      end
      def ordered_hash_subset(hash,keys,opts={},&block)
        seed = ActiveSupport::OrderedHash.new()
        seed.merge!(opts[:seed]) if opts[:seed]
        hash_subset_aux(seed,hash,keys,opts,&block)
      end
     private
      def hash_subset_aux(seed,hash,keys,opts={},&block)
        keys.inject(seed) do |ret,k|
          index = k.kind_of?(Hash) ? k.keys.first : k
          if opts[:only_non_nil] and hash[index].nil?
            ret
          elsif not (hash.has_key?(index) or opts[:include_virtual_columns])
            ret
          else
            key = k.kind_of?(Hash) ? k.values.first : k
            val = 
              if block and block.arity == 1
                block.call(hash[index])
              elsif block and block.arity == 2
                block.call(key,hash[index])
              else  
                hash[index]
              end
            ret.merge(key => val) if ret.respond_to?(:merge)
          end
        end
      end

     public
      # adds to array only if not included
      def array_add?(array,els)
        Array(els).inject(array){|a,el|a.include?(el) ? a : a + [el]}
      end

      def can_take_index?(x)
        x.kind_of?(Hash) or x.kind_of?(Array)
      end

      def ret_key(key_value)
        return nil unless key_value.kind_of?(Hash)
        key_value.keys.first
      end
      def ret_value(key_value)
        return nil unless key_value.kind_of?(Hash)
        key_value.values.first
      end

      def json_parse(json,opts={})
        ret = Hash.new
        if json.empty?
          return ret
        end
        begin 
          ::JSON.parse(json)
        rescue ::JSON::ParserError => e
          return ErrorUsage::Parsing.new("JSON parsing error #{e} in file",opts[:file_path]) if opts[:do_not_raise]
          raise ErrorUsage::Parsing.new("JSON parsing error #{e} in file",opts[:file_path])
        end
      end

      def serialize(hash_content,format_type)
        case format_type
          when :json
            JSON.pretty_generate(hash_content)
          when :yaml
            YamlHelper.dump_simple_form(hash_content)
          else
            raise Error.new("Format (#{format_type}) is not treated")
        end
      end

      def format_type(file_path)
        if file_path =~ /\.(json|yaml)$/
          $1.to_sym
        else
          raise Error.new("Unexpected meta file path name (#{path})")
        end
      end

      def convert_to_hash(content,format_type,opts={})
        case format_type
          when :json
            json_parse(content,opts)
          when :yaml
            YamlHelper.parse(content,opts)
          else
            raise Error.new("Format (#{format_type}) is not treated")
        end
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
            # use pure json to find parsing error
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

      # object or nesting is scalar, Hash or Array
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
        basek = base[key]
        if update.kind_of?(Hash) and basek.kind_of?(Hash)
          update.each{|k,v|merge_into_json_col!(basek,k,v)}
        elsif update.kind_of?(Array) and basek.kind_of?(Array)
          if update.size == basek.size
            update.each_with_index{|upd,i|merge_into_json_col!(basek,i,upd)}
          else
            # If arrays different size, doing a shallow merge
            base[key] = update
          end
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
          # primarily to handle scalars
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

      # TODO: theer may be some exceptions
      def singular?(plural)
        if plural =~ /s$/
          if plural =~ /ies$/
            plural.gsub(/ies$/,'y')
          else
            plural.gsub(/s$/,'')
          end
        else
          plural #input not plural
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
  # TODO: consider variant where third argument passed which is lambda indicating how to 
  # transform inputs before applying to interval method var
  def expose_methods_from_internal_object(innervar,methods_to_expose,opts={})
    if R8::Config[:benchmark]
      return expose_methods_with_benchmark(innervar,methods_to_expose,opts.merge(:benchmark => R8::Config[:benchmark]))
    end 
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

  # TODO: just for testing; 

  def expose_methods_with_benchmark(innervar,methods_to_expose,opts={})
    b = opts[:benchmark]
    post_hook = opts[:post_hook]
    methods_to_expose.each do |m| 
      exec = "@#{innervar}.#{m}(*args)"
      exec = "XYZ::Aux.benchmark('#{m}'){#{exec}}" if b == :all or (b.respond_to?(:include?) and b.include?(m))
      method_def = (post_hook ? "def #{m}(*args);#{post_hook}.call(#{exec});end" : "def #{m}(*args);#{exec};end")
      class_eval(method_def)
    end
  end

  def expose_all_methods_from_internal_object(innervar)
    method_def = "def method_missing(method,*args);@#{innervar}.send(method,*args);end"  
    class_eval(method_def)
  end
end

# for being able to determine the method name in the function call
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

# monkey patch
class Object
  # dups only if object responds to dup
  def dup?()
    return self unless respond_to?(:dup)
    # put in because bug or unexpected result in respond_to? with boolean instances and nil
    return self if nil? or kind_of?(TrueClass) or kind_of?(FalseClass)
    dup
  end
end

=begin
TODO: remove
require 'rack'

module Rack::Utils
  def parse_nested_query(qs, d = nil)
    params = {}
    
    (qs || '').split(d ? /[#{d}] */n : DEFAULT_SEP_MODIFIED).each do |p|
      k, v = unescape(p).split('=', 2)
      normalize_params(params, k, v)
    end
    
    return params
  end
 module_function :parse_nested_query
  DEFAULT_SEP_MODIFIED = /[&] */n
end
=end



