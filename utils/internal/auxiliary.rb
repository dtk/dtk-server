
###for more succinctly handling pattern where class exposes methods on an internal object
class Class
  #TODO: consider variant where third argument passed which is lambda indicating how to 
  #transform inputs before applying to interval method var
  def expose_methods_from_internal_object(innervar,methods_to_expose,opts={})
    methods_to_expose.each do |m| 
      method_def = 
        if opts[:post_hook]
#          "def #{m}(*args);#{opts[:post_hook]}(@#{innervar}.#{m}(*args));end"
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
      attr_reader :model_name_list, :sequel_ds
      def graph(join_type,right_ds,join_conditions)
        right_ds_model_name = right_ds.model_name
        #TBD check whetehr model_name repeats
        model_name_list = @model_name_list + right_ds.model_name_list
        sequel_graph = @sequel_ds.graph(right_ds.sequel_ds,join_conditions,{:join_type => join_type, :table_alias => right_ds_model_name})
        Graph.new(sequel_graph,model_name_list)
      end
      def model_name()
        @model_name_list.first[:ref]
      end
      def model_name_info(model_name,num=0)
        {:ref => model_name, :ref_num => num}
      end
    end

    class Dataset
      include DatatsetGraphMixin
      #TODO: needed to fully qualify Dataset; could this constraint be removed? by chaging expose?
      expose_methods_from_internal_object :sequel_ds, %w{where}, :post_hook => "lambda{|x|XYZ::SQL::Dataset.new(model_name,x)}"
      expose_methods_from_internal_object :sequel_ds, %w{sql}
      def initialize(model_name,sequel_ds)
        @model_name_list = [model_name_info(model_name)]
        @sequel_ds = sequel_ds
      end
    end

    class Graph
      include DatatsetGraphMixin
      #TODO: needed to fully qualify Dataset; could this constraint be removed? by chaging expose?
      expose_methods_from_internal_object :sequel_ds, %w{where}, :post_hook => "lambda{|x|XYZ::SQL::Graph.new(x,@model_name_list)}"
      expose_methods_from_internal_object :sequel_ds, %w{sql}
      def initialize(sequel_ds,model_name_list)
        @sequel_ds = sequel_ds
        @model_name_list = model_name_list
      end
      def all()
        ret = Array.new
        puts @sequel_ds
        raw_result_set = @sequel_ds.all
        raw_result_set.each do |raw_row|
          row = Hash.new
          raw_row.each_key do |model_name|
            next unless raw_row[model_name]
            Model.process_raw_db_row!(raw_row[model_name],model_name)
            raw_row[model_name].each{|k,v|row["#{model_name}__#{k}"] = v} 
          end
          ret << row unless row.empty?
        end
        ret
      end
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

