
###for more succinctly handling pattern where class exposes methods on an internal object
class Class
  #TODO: consider variant where third argument passed which is lambda indicating how to 
  #transform inputs before applying to interval method var
  def expose_methods_from_internal_object(innervar,methods_to_expose,opts={})
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

  def expose_all_methods_from_internal_object(innervar)
    method_def = "def method_missing(method,*args);@#{innervar}.send(method,*args);end"  
    class_eval(method_def)
  end
end

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

    module DatatsetGraphMixin
      attr_reader :model_name_info, :sequel_ds
      def graph(join_type,right_ds,join_conditions)
        new_model_name_info = right_ds.model_name_info.first.create_unique(@model_name_info)
        model_name_info = @model_name_info + [new_model_name_info]
        table_alias = new_model_name_info.ret_qualified_model_name()
        sequel_graph = @sequel_ds.graph(right_ds.sequel_ds,join_conditions,{:join_type => join_type, :table_alias => table_alias})
        Graph.new(sequel_graph,model_name_info)
      end
    end

    class ModelNameInfo 
      attr_reader :model_name,:ref_num
      def initialize(model_name,ref_num=1)
        @model_name = model_name.to_sym
        @ref_num = ref_num
      end
      def ret_qualified_model_name()
        (@ref_num == 1 ? @model_name : "#{@model_name}#{@ref_num.to_s}").to_sym
      end
      def model_name()
        @model_name
      end
      def create_unique(existing_name_info)
        #check whether model_name is in existing_name_info if so bump up by 1
        new_ref_num =  1 + (existing_name_info.find_all{|x|x.model_name == @model_name}.map{|y|y.ref_num}.max || 0)
        ModelNameInfo.new(@model_name,new_ref_num)
      end
    end

    class Dataset
      include DatatsetGraphMixin
      #TODO: needed to fully qualify Dataset; could this constraint be removed? by chaging expose?
      expose_methods_from_internal_object :sequel_ds, %w{where}, :post_hook => "lambda{|x|XYZ::SQL::Dataset.new(model_name,x)}"
      expose_methods_from_internal_object :sequel_ds, %w{sql}
      def initialize(model_name,sequel_ds)
        @model_name_info = [ModelNameInfo.new(model_name)]
        @sequel_ds = sequel_ds
      end
    end

    class Graph
      include DatatsetGraphMixin
      #TODO: needed to fully qualify Dataset; could this constraint be removed? by chaging expose?
      expose_methods_from_internal_object :sequel_ds, %w{where}, :post_hook => "lambda{|x|XYZ::SQL::Graph.new(x,@model_name_info)}"
      expose_methods_from_internal_object :sequel_ds, %w{sql}
      def initialize(sequel_ds,model_name_info)
        @sequel_ds = sequel_ds
        @model_name_info = model_name_info
      end
      def all()
        #TODO may be more efficient if flatten by use something like Model.db.db[@sequel_ds.sql].all
        # this avoids needing to reanchor each from primary table (which should be bulk of info
        ret = @sequel_ds.all
        
        #pull first element from under top level key
        primary_model_name = @model_name_info.first.model_name() 
        rest_model_indexes = @model_name_info[1..@model_name_info.size-1]
        ret.each do |row|
          primary_cols = row.delete(primary_model_name)
          Model.process_raw_db_row!(primary_cols,primary_model_name)
          primary_cols.each{|k,v|row[k] = v}
          rest_model_indexes.each do |m|
            model_index = m.ret_qualified_model_name()
            next unless row[model_index]
            Model.process_raw_db_row!(row[model_index],m.model_name)
          end
        end
        ret
      end
    end
  end  

  class Aux
    class << self
      
      def create_object_slice(hash,slice_keys,opts={})
        ret = Hash.new
        slice_keys.each do |k|
          val = hash[k]
          ret[k] = val if (val or opts[:include_null_cols])
        end
        ret
      end

      def fill_in_virtual_columns!(hash,model_name,slice_keys,opts={})
        #keys in slice_keys no in hash should be virtual columns
        (slice_keys - hash.keys).each do |k|
          fn = Model::FieldSet.virtual_column_lambda_fn(model_name,k)
          hash[k] = fn.call(hash) if fn
        end
        hash
      end

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

