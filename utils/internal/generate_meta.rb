module XYZ
  class GenerateMeta
    def self.create(version)
      case version
      when "1.0" then new(version)
        else rase Error.new("Unexpected version (#{version})")
      end
    end

    def generate_hash(parse_struct)
      MetaObject.new(:version => @version).create(:module,parse_structure)
    end

   private
    def initilaize(version)
      @version = version
    end
  end

  class MetaObject < SimpleHashObject
    def initialize(context)
      @context = context
    end
    def create(type,parse_struct)
      klass(type).new(parse_struct,@context)
    end
   private
    def klass(type)
      mod = XYZ.const_get "V#{version.gsub(".","_")}"
      mod.const_get "#{type.to_s.capitalize}Meta"
    end
    def version()
      (@context||{})[:version]
    end
  end
  class ModuleMeta < MetaObject
    def initialize(top_parse_struct,context)
      super(context)
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
    end
  end
  class AttributeMeta < MetaObject
  end

  #handles intermediate state where objects may be unkonw an djust need users input
  class MetaTerm < SimpleHashObject
    def initialize(value,state=:known)
      self[:value] = value
      self[:state] = state
    end
  end
end
require File.expand_path("generate_meta/version-1.0.rb", File.dirname(__FILE__))

