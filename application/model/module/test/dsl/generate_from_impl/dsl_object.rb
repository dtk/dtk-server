module DTK; class TestDSL
  class GenerateFromImpl
    module CommonMixin
      def set_hash_key(key)
        self[:id] = key
        key
      end
      def hash_key()
        self[:id]
      end
      
      def create_external_ref(name,type)
        DSLObject::RenderHash.new([{"name" => name},{"type" => type}])
      end
      
      def sanitize_attribute(attr)
        attr.gsub(/[^a-zA-Z0-9_-]/,"-")
      end
      def t(term)
        term
        # TODO probably remove return nil if term.nil?
        # DSLTerm.new(term)
      end
      def unknown
        nil
        # TODO: probably remove DSLTerm.create_unknown
      end
      def nailed(term)
        term #TODO: may also make this a DSLTerm obj
      end
    end

    r8_nested_require('dsl_object','store_config_handler')
    include StoreConfigHandlerMixin

    class DSLStructObject < SimpleOrderedHash
      def initialize(type,content,opts={})
        if opts[:reify]
          super([{:type => type.to_s},{:required => opts[:required]},{:def => content}])
        else
          super([{:type => type.to_s},{:required => nil},{:def => content}])
          self[:required] = content.delete(:include)
        end
      end

      def hash_key()
        self[:def].hash_key()
      end

      def render_hash_form(opts={})
        self[:def].render_hash_form(opts)
      end
    end

    class DSLArray < Array
      def each_element(opts={},&block)
        each do |el|
          unless opts[:skip_required_is_false] and (not el.nil?) and not el
            block.call(el[:def]) 
          end
        end
      end

      def map_element(opts={},&block)
        ret = Array.new
        each do |el|
          unless opts[:skip_required_is_false] and (not el.nil?) and not el
            ret << block.call(el[:def]) 
          end
        end
        ret
      end

      def  +(a2)
        ret = self.class.new
        each{|x|ret << x}
        a2.each{|x|ret << x}
        ret
      end
    end

    class DSLObject < SimpleOrderedHash
      r8_nested_require('dsl_object','object_classes')
      include CommonMixin
      def initialize(context,opts={})
        super()
        @context = context
        create_in_object_form(opts[:def]) if opts[:reify]
      end
      # TODO: make as part of context
      ScaffoldingStrategy = {
        :no_dynamic_attributes => true,
        :no_defaults => true,
        :ignore_components => ['params']
      }

      def create(type,parse_struct,opts={})
        DSLStructObject.new(type,klass(type).new(parse_struct,@context.merge(opts)))
      end

      # dup used because yaml generation is upstream and dont want string refs
      def required_value(key)
        unless has_key?(key)
          raise Error.new("meta object does not have key #{key}") 
        end

        value_term = self[key]
        raise Error.new("meta object with key #{key} is null") if value_term.nil? 
        return value_term.dup unless value_term.kind_of?(DSLTerm)
        
        unless value_term.is_known?()
          raise Error.new("meta object with key #{key} has unknown value")
        end
        value_term.value.dup
      end
      
      def value(key)
        value_term = self[key]
        return nil if value_term.nil?
        return value_term unless value_term.kind_of?(DSLTerm)
        value_term.is_known?() ? value_term.value : nil
      end

      def set_source_ref(parse_struct)
        @context[:source_ref] = parse_struct
      end

      # functions to convert to object form
      def reify(hash)
        type = index(hash,:type)
        content = klass(type).new(nil,@context,{:reify => true, :def => index(hash,:def)})
        DSLStructObject.new(type,content,{:reify => true, :required => index(hash,:required)})
      end

     private
      # functions to treat object functions
      # can be overwritten
      def object_attributes()
        []
      end
      def index(hash,key)
        if hash.has_key?(key.to_s)
          hash[key.to_s]
        elsif hash.has_key?(key.to_sym)
          hash[key.to_sym]
        end
      end

      def has_index?(hash,key)
        hash.has_key?(key.to_s) or hash.has_key?(key.to_sym)
      end

      def create_in_object_form(hash)
        hash.each{|k,v|self[k.to_sym] = convert_value_if_needed(k,v)}
      end
      
      def convert_value_if_needed(key,val)
        return val unless object_attributes().include?(key.to_sym)
        
        if val.kind_of?(Array)
          ret = DSLArray.new
          val.each{|el_val| ret << reify(el_val) if selected?(el_val)}
          ret
        else
          # TODO: no check for selcted here?
          reify(val)
        end
      end

      def selected?(hash)
        index(hash,:selected) or not has_index?(hash,:selected) #default is 'selected'
      end

      ###utilities
      def is_foreign_component_name?(name)
        if name =~ /(^.+)::.+$/
          prefix = $1
          prefix == module_name ? nil : true
        end
      end
      
      def klass(type)
        version_class = TestDSL.load_and_return_version_adapter_class(integer_version())
        cap_type = type.to_s.split("_").map{|t|t.capitalize}.join("")
        version_class.const_get("DSLObject").const_get(cap_type)
      end

      # context
      def integer_version()
        (@context||{})[:integer_version]
      end
      def module_name()
        (@context||{})[:module_name]
      end
      def config_agent_type()
        (@context||{})[:config_agent_type]
      end
      public
      def parent()
        (@context||{})[:parent]
      end
      def parent_source()
        (@context||{})[:parent_source]
      end
      def source_ref()
        (@context||{})[:source_ref]
      end
  
      # TODO: may deprecate
      # handles intermediate state where objects may be unknown and just need users input
      class DSLTerm < SimpleHashObject
        def initialize(value,state=:known)
          self[:value] = value if state == :known
          self[:state] = state
        end
        def self.create_unknown()
          new(nil,:unknown)
        end
        
        def set_value(v)
          self[:state] = :known
          self[:value] = v
        end

        def value()
          self[:value]
        end
        def is_known?()
          self[:state] == :known
        end
      end
      
      class VarMatches < Array
        def add(input_var,output_var)
          self << {:input_var => input_var,:output_var => output_var}
          self
        end
        def +(a2)
          ret = self.class.new
          each{|x|ret << x}
          a2.each{|x|ret << x}
          ret
        end
      end
      
      class RenderHash < SimpleOrderedHash
        def serialize(format_type=nil)
          format_type ||= TestDSL.default_format_type()
          if format_type == :yaml
            Aux.serialize(yaml_form(),format_type)
          else
            Aux.serialize(self,format_type)
          end
        end

        # TODO: deprecate
        def write_yaml(io)
          require 'yaml'
          YAML::dump(yaml_form(),io)
          io << "\n"
        end

        # since yaml generator is being used want to remove references so dont generate yaml with labels
        def yaml_form(level=1)
          ret = RenderHash.new
          each do |k,v|
            if level == 1 and k == "version"
              next
            end
            converted_val = 
              if v.kind_of?(RenderHash)
                v.yaml_form(level+1)
              elsif v.kind_of?(Array)
                v.map{|el|el.kind_of?(RenderHash) ? el.yaml_form(level+1) : el.dup?}
              else 
                v.dup?
              end
            ret[k.dup?] = converted_val 
          end
          ret
        end
      end
    end
  end
end; end

