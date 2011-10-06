module XYZ
  class GenerateMeta
    def self.create(version)
      case version
      when "1.0" then new(version)
        else raise Error.new("Unexpected version (#{version})")
      end
    end

    def generate_hash(parse_struct,module_name)
      context = {
        :version => @version,
        :module_name => module_name
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

    def klass(type)
      mod = XYZ.const_get "V#{version.gsub(".","_")}"
      mod.const_get "#{type.to_s.capitalize}Meta"
    end
    def version()
      (@context||{})[:version]
    end
    def moudle_name()
      (@context||{})[:module_name]
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
  end
  class AttributeMeta < MetaObject
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

