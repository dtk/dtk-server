module XYZ
  class GenerateMeta
    def self.create(version)
      case version
      when "1.0" then new(version)
        else raise Error.new("Unexpected version (#{version})")
      end
    end

    def generate_hash(parse_struct,module_name,config_agent_type)
      context = {
        :version => @version,
        :module_name => module_name,
        :config_agent_type => config_agent_type
      }
      MetaObject.new(context).create(:module,parse_struct)
    end

   private
    def initialize(version)
      @version = version
    end
  end

  class MetaObject < SimpleOrderedHash
    def initialize(context)
      super()
      @context = context
    end
    def create(type,parse_struct)
      klass(type).new(parse_struct,@context)
    end
   private
    def set_hash_key(key)
      self[:hash_key] = key
    end
    def t(term)
      MetaTerm.new(term)
    end
    def unknown
      MetaTerm.create_unknown
    end
    def nailed(term)
      term #TODO: may also make this a MetaTerm obj
    end
    def klass(type)
      mod = XYZ.const_get "V#{version.gsub(".","_")}"
      mod.const_get "#{type.to_s.capitalize}Meta"
    end
    
    #context
    def version()
      (@context||{})[:version]
    end
    def module_name()
      (@context||{})[:module_name]
    end
    def config_agent_type()
      (@context||{})[:config_agent_type]
    end
  end

  class ModuleMeta < MetaObject
    def initialize(top_parse_struct,context)
      super(context)
      self[:version] = context[:version]
      top_parse_struct.each_component do |component_ps|
        (self[:components] ||= Array.new) << create(:component,component_ps)
      end
    end

    def render_to_file(file,format)
    end
  end
  class ComponentMeta < MetaObject
    def initialize(component_ps,context)
      super(context)
      processed_name = component_ps[:name]
      #if qualified name make sure matches module name
      if processed_name =~ /(^.+)::(.+$)/
        prefix = $1
        unqual_name = $2
        if processed_name =~ /::.+::/
          raise Error.new("unexpected class or definition name #{processed_name})")
        end
        unless prefix == module_name
          raise Error.new("prefix (#{prefix}) not equal to module name (#{module_name})")
        end 
        processed_name = "#{module_name}__#{unqual_name}"
      end

      set_hash_key(processed_name)
      self[:required] = unknown
      self[:display_name] = t(processed_name) #TODO: might instead put in label
      self[:description] = unknown
      type = "#{config_agent_type}_#{component_ps[:type]}"
      external_ref = SimpleOrderedHash.new().merge(:name => component_ps[:name]).merge(:type => type)
      self[:external_ref] = nailed(external_ref) 
      attributes = (component_ps[:attributes]||[]).map{|attr_ps|create(:attribute,attr_ps)}
      self[:attributes] = attributes unless attributes.empty?
    end
  end

  class AttributeMeta < MetaObject
    def initialize(attr_ps,context)
      super(context)
      name = attr_ps[:name]
      set_hash_key(name)
      self[:display_name] = t(name) 
      self[:description] = unknown
      if default = attr_ps[:default]
        self[:default] = t(default)
      end
      self[:required] = (attr_ps.has_key?(:required) ? nailed(attr_ps[:required]) : unknown)
      self[:external_ref] = nailed(SimpleOrderedHash.new().merge(:name => attr_ps[:name]))
    end
  end

  #handles intermediate state where objects may be unknown and just need users input
  class MetaTerm < SimpleHashObject
    def initialize(value,state=:known)
      self[:value] = value if state == :known
      self[:state] = state
    end
    def self.create_unknown()
      new(nil,:unknown)
    end
  end
end
require File.expand_path("generate_meta/version-1.0.rb", File.dirname(__FILE__))

