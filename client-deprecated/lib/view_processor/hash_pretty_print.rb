dtk_require_util_library("hash_object") 

module DTK
  module Client
    class ViewProcHashPrettyPrint < ViewProcessor
      include XYZ
      include Aux
      def render(hash)
        object_def = get_top_def()
        raise_error() unless object_def
        render_object_def(hash,object_def)
      end
     private
      attr_reader :meta
      def initialize(type,command_class)
        super(type,command_class)
        @meta = get_meta(type,command_class)
      end

      def failback_meta(ordered_cols)
        {
          :top_type => :top,
          :defs => {:top_def => ordered_cols}
        }
      end

      def get_top_def()
        raise_error("No Top def") unless top_object_type = meta[:top_type]
        get_object_def(top_object_type)
      end

      def get_object_def(object_type)
        if defs = meta[:defs] and object_type
          {object_type => defs["#{object_type}_def".to_sym]}
        end
      end
      def raise_error(msg=nil)
        msg ||= "No hash pretty print view defined"
        raise Error.new(msg)
      end
      def render_object_def(object,object_def,opts={})
        #TODO: stub making it only first level
        return object unless object.kind_of?(Hash)
        hash = object
        ret = ViewPrettyPrintHash.new(object_def.keys.first)

        object_def.values.first.each do |item|
          if item.kind_of?(Hash)
            render_object_def__hash_def!(ret,hash,item)
          else
            key = item.to_s
            target_key = replace_with_key_alias?(key) 
            #TODO: may want to conditionally include nil values
            ret[target_key] = hash[key] if hash[key]
          end
        end
        #catch all for keys not defined
        unless opts[:only_explicit_cols]
          (hash.keys.map{|k|replace_with_key_alias?(k)} - ret.keys).each do |key|
            ret[key] = hash[key] if hash[key]
          end
        end
        ret
      end
      def replace_with_key_alias?(key)
        #TODO: fix
        return key
        if ret = GlobalKeyAliases[key.to_sym] then ret.to_s 
        else key
        end
      end
      GlobalKeyAliases = {
        :library_library_id => :library_id,
        :datacenter_datacenter_id => :target_id
      }


      def render_object_def__hash_def!(ret,hash,hash_def_item)
        key = hash_def_item.keys.first.to_s
        return unless input = hash[key]
        hash_def_info = hash_def_item.values.first
        nested_object_def = get_object_def(hash_def_info[:type])
        raise_error("object def of type (#{hash_def_info[:type]||""}) does not exist") unless nested_object_def

        opts = Hash.new
        if hash_def_info[:only_explicit_cols]
          opts.merge!(:only_explicit_cols => true)
        end
        if hash_def_info[:is_array]
          raise_error("hash subpart should be an array") unless input.kind_of?(Array)
          ret[key] = input.map{|el|render_object_def(el,nested_object_def,opts)}
        else
          ret[key] = render_object_def(input,nested_object_def,opts)
        end
      end
    end
    class ViewPrettyPrintHash < ::XYZ::PrettyPrintHash
      def initialize(object_type=nil)
        super()
        @object_type = object_type
      end
      attr_accessor :object_type
      def slice(*keys)
        ret = super
        ret.object_type = object_type
        ret
      end
    end
  end
end
