module XYZ
  module CommonGenerateMetaMixin
    def t(term)
      term
      #TODO probably remove return nil if term.nil?
      #MetaTerm.new(term)
    end
    def unknown
      nil
      #TODO: probably remove MetaTerm.create_unknown
    end
    def nailed(term)
      term #TODO: may also make this a MetaTerm obj
    end

    def set_hash_key(key)
      self[:id] = key
      key
    end
    def hash_key()
      self[:id]
    end

    def sanitize_attribute(attr)
      attr.gsub(/[^a-zA-Z0-9_-]/,"-")
    end
  end
  require File.expand_path("generate_meta/store_config_handler", File.dirname(__FILE__))
  class GenerateMeta
    def self.create(version)
      case version
      when "1.0" then new(version)
        else raise Error.new("Unexpected version (#{version})")
      end
    end
    def generate_refinement_hash(parse_struct,module_name)
      context = {
        :version => @version,
        :module_name => module_name,
        :config_agent_type => parse_struct.config_agent_type
      }
      MetaObject.new(context).create(:module,parse_struct)
    end

   private
    def initialize(version)
      @version = version
    end
  end

  class MetaStructObject < SimpleOrderedHash
    def initialize(content)
      super([{:required => nil},{:content => content}])
      self[:required] = content.delete(:include)
    end
    
    def hash_key()
      self[:content].hash_key()
    end

    def render_hash_form(opts={})
      self[:content].render_hash_form(opts)
    end
  end

  class MetaArray < Array
    def each_element(opts={},&block)
      each do |el|
        unless opts[:skip_required_is_false] and (not el.nil?) and not el
          block.call(el[:content]) 
        end
      end
    end

    def map_element(opts={},&block)
      ret = Array.new
      each do |el|
        unless opts[:skip_required_is_false] and (not el.nil?) and not el
          ret << block.call(el[:content]) 
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

  class MetaObject < SimpleOrderedHash
    include CommonGenerateMetaMixin
    include StoreConfigHandlerMixin
    def initialize(context)
      super()
      @context = context
    end
    def create(type,parse_struct,opts={})
      MetaStructObject.new(klass(type).new(parse_struct,@context.merge(opts)))
    end

    #dup used because yaml generation is upstream and dont want string refs
    def required_value(key)
      unless has_key?(key)
        raise Error.new("meta object does not have key #{key}") 
      end

      value_term = self[key]
      raise Error.new("meta object with key #{key} is null") if value_term.nil? 
      return value_term.dup unless value_term.kind_of?(MetaTerm)
      
      unless value_term.is_known?()
        raise Error.new("meta object with key #{key} has unknown value")
      end
      value_term.value.dup
    end

    def value(key)
      value_term = self[key]
      return nil if value_term.nil?
      return value_term unless value_term.kind_of?(MetaTerm)
      value_term.is_known?() ? value_term.value : nil
    end

    def set_source_ref(parse_struct)
      @context[:source_ref] = parse_struct
    end

   private
    ###utilities
    def is_foreign_component_name?(name)
      if name =~ /(^.+)::.+$/
        prefix = $1
        prefix == module_name ? nil : true
      end
    end

    def klass(type)
      mod = XYZ.const_get "V#{version.gsub(".","_")}"
      cap_type = type.to_s.split("_").map{|t|t.capitalize}.join("")
      mod.const_get "#{cap_type}Meta"
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
  end
  
  class ModuleMeta < MetaObject
    def initialize(top_parse_struct,context)
      super(context)
      self[:components] = MetaArray.new
      top_parse_struct.each_component do |component_ps|
        self[:components] << create(:component,component_ps)
      end
      process_imported_resources()
    end

    def render_to_file(file,format)
    end
   private
    def process_imported_resources()
      #first get all the exported resources and imported resources
      #TODO: more efficient to store these in first phase
      attr_exp_rscs = Array.new
      attr_imp_colls = Array.new
      self[:components].each_element do |cmp|
        cmp[:attributes].each_element do |attr|
          parse_struct = attr.source_ref
          if parse_struct
            if parse_struct.is_exported_resource?()
              attr_exp_rscs << attr
            elsif parse_struct.is_imported_collection?()
              attr_imp_colls << attr
            end
          end
        end
      end
      return if attr_exp_rscs.empty? or attr_imp_colls.empty?
      matches = Array.new
      attr_imp_colls.each do |attr_imp_coll|
        if match = matching_storeconfig_vars?(attr_imp_coll,attr_exp_rscs)
          data = {
            :type => :imported_collection, 
            :attr_imp_coll => attr_imp_coll, 
            :attr_exp_rsc => match[:attr_exp_rsc],
            :matching_vars => match[:vars]
          }
          if link_def = create(:link_def,data)
            (attr_imp_coll.parent[:link_defs] ||= MetaArray.new) << link_def
          end
        end
      end
    end
    def matching_storeconfig_vars?(attr_imp_coll,attr_exp_rscs)
      attr_exp_rscs.each do |attr_exp_rsc|
        if matching_vars = attr_imp_coll.source_ref.match_exported?(attr_exp_rsc.source_ref)
          return {:vars => matching_vars, :attr_exp_rsc => attr_exp_rsc} 
        end
      end
      nil
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
      self[:display_name] = t(processed_name) #TODO: might instead put in label
      self[:description] = unknown
      self[:ui_png] = unknown
      type = "#{component_ps.config_agent_type}_#{component_ps[:type]}"
      external_ref = RenderHash.new([{:name => component_ps[:name]},{:type => type}])
      self[:external_ref] = nailed(external_ref) 
      self[:basic_type] = unknown
      self[:component_type] = t(processed_name)
      dependencies = dependencies(component_ps)
      self[:dependencies] = dependencies unless dependencies.empty?
      set_attributes(component_ps)
    end
   private
    def dependencies(component_ps)
      ret = MetaArray.new
      ret += find_foreign_resource_names(component_ps).map do |name|
        create(:dependency,{:type => :foreign_dependency, :name => name})
      end
      #TODO: may be more  dependency types
      ret
    end

    def set_attributes(component_ps)
      attr_num = 0
      self[:attributes] = MetaArray.new
      (component_ps[:attributes]||[]).each{|attr_ps|add_attribute(attr_ps,component_ps,attr_num+=1)}

      (component_ps[:children]||[]).each do |child_ps|
        if child_ps.is_imported_collection?()
          add_attribute(child_ps,component_ps,attr_num+=1)
        elsif child_ps.is_exported_resource?()
          add_attribute(child_ps,component_ps,attr_num+=1)
        end
      end
    end

    def add_attribute(parse_structure,component_ps,attr_num)
      opts = {:attr_num => attr_num, :parent => self, :parent_source => component_ps}
      self[:attributes] << create(:attribute,parse_structure,opts)
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

  #TODO: see if makes sense to handle the exported resource link defs heere while using store confif helper file to deal with attributes
  module LinkDefMetaMixin
    def initialize(data,context)
      super(context)
      case data[:type]
        when :imported_collection then initialize__imported_collection(data)
        else raise Error.new("unexpeced link def type (#{data[:type]})")
      end
    end
  end

  class LinkDefMeta < MetaObject
    include LinkDefMetaMixin
   private
    def initialize__imported_collection(data)
      self[:include] = true
      self[:required] = nailed(true)
      self[:type] = t(data[:attr_exp_rsc].parent.hash_key)
      self[:possible_links] = (MetaArray.new << create(:link_def_possible_link,data))
    end
  end
  class LinkDefPossibleLinkMeta < MetaObject
    include LinkDefMetaMixin
    def initialize__imported_collection(data)
      self[:include] = true
      output_component = data[:attr_exp_rsc].parent.hash_key
      set_hash_key(output_component)
      self[:type] = nailed("external")
      StoreConfigHandler.add_attribute_mappings!(self,data)
    end
    def create_attribute_mapping(input,output,opts={})
      data = {:input => input, :output => output}
      data.merge!(:include => true) if opts[:include]
      create(:link_def_attribute_mapping,data)
    end
  end

  class LinkDefAttributeMappingMeta  < MetaObject
    def initialize(data,context)
      super(context)
      self[:include] = true if data[:include]
      self[:output] = data[:output]
      self[:input] = data[:input]
    end
  end


  class AttributeMeta < MetaObject
    def initialize(parse_struct,context)
      super(context)
      set_source_ref(parse_struct)
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

    def attr_num()
      (@context||[])[:attr_num]
    end

    def set_hash_key(key_x)
      key = key_x
      num = 1
      existing_keys = existing_hash_keys()
      while existing_hash_keys().include?(key)
        key = "#{key_x}#{(num+=1).to_s}"
      end
      super(key)
    end

   private
    def initialize__from_attribute(attr_ps)
      name = sanitize_attribute(attr_ps[:name])
      set_hash_key(name)
      self[:field_name] = t(name) 
      self[:label] = t(name) 
      self[:description] = unknown
      self[:type] = t("string") #TODO: stub
      var_default = nil
      if default = attr_ps[:default]
        var_default = default.contains_variable?()
        self[:default_info] = var_default ? unknown : t(default.to_s) 
      end
      if var_default
        self[:required] = t(false)
      else
        self[:required] = (attr_ps.has_key?(:required) ? nailed(attr_ps[:required]) : unknown)
        self[:include] = true if attr_ps[:required]
      end

      ext_ref = RenderHash.new(:name => attr_ps[:name])
      ext_ref.merge!("default_variable" => default.to_s) if var_default
      self[:external_ref] = nailed(ext_ref)
    end
    def initialize__from_exported_resource(exp_rsc_ps)
      StoreConfigHandler.set_output_attribute!(self,exp_rsc_ps)
    end
    def initialize__from_imported_collection(imp_coll_ps)
      StoreConfigHandler.set_intput_attribute!(self,imp_coll_ps)
    end

    def existing_hash_keys()
      ((parent||{})[:attributes]||[]).map{|a|a.hash_key}.compact
    end
  end

  #TODO: may deprecate
  #handles intermediate state where objects may be unknown and just need users input
  class MetaTerm < SimpleHashObject
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
    def write_yaml(io)
      require 'yaml'
      YAML::dump(yaml_form(),io)
      io << "\n"
    end
  protected
    #since zaml generator is beiung used waht to remove references so dont generate yaml with labels
    def yaml_form()
      ret = RenderHash.new
      each do |k,v|
        converted_val = 
          if v.kind_of?(RenderHash)
            v.yaml_form()
          elsif v.kind_of?(Array)
            v.map{|el|el.kind_of?(RenderHash) ? el.yaml_form() : el.dup?}
          else 
            v.dup?
          end
        ret[k.dup?] = converted_val 
      end
      ret
      end
  end
end

#TODO: when have multiple versions may dynamically load
require File.expand_path("generate_meta/versions/V1.0.rb", File.dirname(__FILE__))

