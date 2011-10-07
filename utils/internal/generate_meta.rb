require File.expand_path("generate_meta/exported_resource_handler", File.dirname(__FILE__))
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
    include ExportedResourceHandlerMixin
    def initialize(context)
      super()
      @context = context
    end
    def create(type,parse_struct)
      klass(type).new(parse_struct,@context)
    end

   private
    ###utilities
    def is_foreign_component_name?(name)
      if name =~ /(^.+)::.+$/
        prefix = $1
        prefix == module_name ? nil : true
      end
    end

    def set_hash_key(key)
      self[:hash_key] = key
    end
    def klass(type)
      mod = XYZ.const_get "V#{version.gsub(".","_")}"
      mod.const_get "#{type.to_s.capitalize}Meta"
    end

    #wrappers for terms
    def t(term)
      MetaTerm.new(term)
    end
    def unknown
      MetaTerm.create_unknown
    end
    def nailed(term)
      term #TODO: may also make this a MetaTerm obj
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
      self[:include] = unknown 
      self[:display_name] = t(processed_name) #TODO: might instead put in label
      self[:description] = unknown
      type = "#{config_agent_type}_#{component_ps[:type]}"
      external_ref = SimpleOrderedHash.new().merge(:name => component_ps[:name]).merge(:type => type)
      self[:external_ref] = nailed(external_ref) 
      dependencies = dependencies(component_ps)
      self[:dependencies] = dependencies unless dependencies.empty?
      attributes = attributes(component_ps)
      self[:attributes] = attributes unless attributes.empty?
    end
   private
    def dependencies(component_ps)
      ret = Array.new
      ret += find_foreign_resource_names(component_ps).map do |name|
        create(:dependency,{:type => :foreign_dependency, :name => name})
      end
      #TODO: may be more  dependency types
      ret
    end
    
    def attributes(component_ps)
      ret = (component_ps[:attributes]||[]).map{|attr_ps|create(:attribute,attr_ps)}
      (component_ps[:children]||[]).each do |child_ps|
        if child_ps.is_imported_collection?()
          ret << create(:attribute,child_ps)
        elsif child_ps.is_exported_resource?()
          ret << create(:attribute,child_ps)
        end
      end
      ret
    end

    def find_foreign_resource_names(component_ps)
      ret = Array.new
      (component_ps[:children]||[]).each do |child|
        next unless child.is_defined_resource?()
        name = child[:name]
        next unless is_foreign_component_name?(name)
        ret << name unless ret.include?(name)
      end
      ret
    end
  end

  class DependencyMeta < MetaObject
    def initialize(data,context)
      super(context)
      self[:type] = nailed(data[:type].to_s)
      case data[:type]
        when :foreign_dependency
          self[:name] = data[:name]
        else raise Error.new("Unexpected dependency type (#{data[:type]})")
      end
    end
  end

  class AttributeMeta < MetaObject
    def initialize(parse_struct,context)
      super(context)
      if parse_struct.is_attribute?()
        initialize__from_attribute(parse_struct)
      elsif parse_struct.is_exported_resource?()
        initialize__from_exported_resource(parse_struct)
      elsif parse_struct.is_imported_collection?()
        initialize__from_imported_collection(parse_struct)
      else
        raise Error.new("Unexpected parse structure type (#{parse_struct.class.to_s})")
      end  
    end
   private
    def initialize__from_attribute(attr_ps)
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
    def initialize__from_exported_resource(exp_rsc_ps)
      ExportedResourceHandler.create_attribute(exp_rsc_ps)
    end
    def initialize__from_imported_collection(imp_coll_ps)
      #TODO: stub
      imp_coll_ps
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
require File.expand_path("generate_meta/versions/V1.0.rb", File.dirname(__FILE__))

