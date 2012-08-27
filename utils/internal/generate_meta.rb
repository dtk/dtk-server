module XYZ
  module CommonGenerateMetaMixin
    def set_hash_key(key)
      self[:id] = key
      key
    end
    def hash_key()
      self[:id]
    end

    def create_external_ref(name,type)
      RenderHash.new([{"name" => name},{"type" => type}])
    end

    def sanitize_attribute(attr)
      attr.gsub(/[^a-zA-Z0-9_-]/,"-")
    end
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
  end
  require File.expand_path("generate_meta/store_config_handler", File.dirname(__FILE__))
  class GenerateMeta
    def self.create(version)
      case version
      when "1.0" then new(version)
        else raise Error.new("Unexpected version (#{version})")
      end
    end
    def generate_refinement_hash(parse_struct,module_name,impl_idh)
      context = {
        :version => @version,
        :module_name => module_name,
        :config_agent_type => parse_struct.config_agent_type,
        :implementation_id => impl_idh.get_id()
      }
      MetaObject.new(context).create(:module,parse_struct)
    end

    def self.save_meta_info(meta_info_hash,impl_mh)
      version = meta_info_hash["version"]
      config_agent_type = meta_info_hash["config_agent_type"]
      module_name = meta_info_hash["module_name"]
      components = meta_info_hash["components"]
      impl_id = meta_info_hash["implementation_id"]
      module_hash = {
        :required => true,
        :type => "module",
        :def => {"components" => components}
      }
      impl_obj = impl_mh.createIDH(:id => impl_id).create_object().update_object!(:id,:display_name,:type,:repo_id,:repo,:library_library_id)
      impl_idh = impl_obj.id_handle
      library_idh = impl_idh.createIDH(:model_name => :library,:id => impl_obj[:library_library_id])
      repo_obj = Model.get_obj(impl_idh.createMH(:repo),{:cols => [:id,:local_dir], :filter => [:eq, :id, impl_obj[:repo_id]]})
                                       
      meta_generator = GenerateMeta.create(version)
      object_form = meta_generator.reify(module_hash,module_name,config_agent_type)
      r8meta_hash = object_form.render_hash_form()

      r8meta_hash.delete("version") #TODO: currently version not handled in add_components_from_r8meta

      r8meta_path = "#{repo_obj[:local_dir]}/r8meta.#{config_agent_type}.yml"
      r8meta_hash.write_yaml(STDOUT)
      File.open(r8meta_path,"w"){|f|r8meta_hash.write_yaml(f)}

      #this wil add any file_assets that have not been yet added (this will include the r8meta file
      impl_obj.create_file_assets_from_dir_els(repo_obj)

      ComponentMetaFile.add_components_from_r8meta(library_idh,config_agent_type,impl_idh,r8meta_hash)

      impl_obj.add_contained_files_and_push_to_repo()
    end

    
    def reify(hash,module_name,config_agent_type)
      context = {
        :version => @version,
        #TODO: do we neeed module_name and :config_agent_type for reify?
        :module_name => module_name,
        :config_agent_type => config_agent_type
      }
      MetaObject.new(context).reify(hash)
    end

   private
    def initialize(version)
      @version = version
    end
  end

  class MetaStructObject < SimpleOrderedHash
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

  class MetaArray < Array
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

  class MetaObject < SimpleOrderedHash
    include CommonGenerateMetaMixin
    include StoreConfigHandlerMixin
    def initialize(context,opts={})
      super()
      @context = context
      create_in_object_form(opts[:def]) if opts[:reify]
    end

    def create(type,parse_struct,opts={})
      MetaStructObject.new(type,klass(type).new(parse_struct,@context.merge(opts)))
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

    #functions to convert to object form
    def reify(hash)
      type = index(hash,:type)
      content = klass(type).new(nil,@context,{:reify => true, :def => index(hash,:def)})
      MetaStructObject.new(type,content,{:reify => true, :required => index(hash,:required)})
    end

  private
    #functions to treat object functions
    #can be overwritten
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
        ret = MetaArray.new
        val.each{|el_val| ret << reify(el_val) if selected?(el_val)}
        ret
      else
        #TODO: no check for selcted here?
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
    def initialize(top_parse_struct,context,opts={})
      super(context,opts)
      return if opts[:reify]
      context.each{|k,v|self[k] = v}
      self[:components] = MetaArray.new
      top_parse_struct.each_component do |component_ps|
        self[:components] << create(:component,component_ps)
      end
      process_imported_resources()
    end

    def render_to_file(file,format)
    end
   private
    def object_attributes()
      [:components]
    end

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
      #get all teh matches
      matches = Array.new
      matches = attr_imp_colls.map do |attr_imp_coll|
        if match = matching_storeconfig_vars?(attr_imp_coll,attr_exp_rscs)
          {
            :type => :imported_collection, 
            :attr_imp_coll => attr_imp_coll, 
            :attr_exp_rsc => match[:attr_exp_rsc],
            :matching_vars => match[:vars]
          }
        end
      end.compact
      return if matches.empty?
      set_user_friendly_names_for_storeconfig_vars!(matches)

      #create link defs
      matches.each do |match|
        if link_def = create(:link_def,match)
          (match[:attr_imp_coll].parent[:link_defs] ||= MetaArray.new) << link_def
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

    def set_user_friendly_names_for_storeconfig_vars!(matches)
      translated_ids = Array.new
      matches.each do |match|
        imp_attr = match[:attr_imp_coll]
        exp_attr = match[:attr_exp_rsc]
        unless translated_ids.include?(imp_attr[:id])
          translated_ids << imp_attr[:id]
          imp_attr.reset_hash_key_and_name_fields("import_from_#{exp_attr.parent[:id]}")
        end
        unless translated_ids.include?(exp_attr[:id])
          translated_ids << exp_attr[:id]
          exp_attr.reset_hash_key_and_name_fields("export_to_#{imp_attr.parent[:id]}")
        end
      end
    end
  end

  class ComponentMeta < MetaObject
    def initialize(component_ps,context,opts={})
      super(context,opts)
      return if opts[:reify]
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
      external_ref = create_external_ref(component_ps[:name],type)
      self[:external_ref] = nailed(external_ref) 
      self[:basic_type] = t("service") #TODO: stub
      self[:component_type] = t(processed_name)
      dependencies = dependencies(component_ps)
      self[:dependencies] = dependencies unless dependencies.empty?
      set_attributes(component_ps)
    end
   private
    def object_attributes()
      [:attributes,:dependencies,:link_defs]
    end
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
    def initialize(data,context,opts={})
      super(context,opts)
      return if opts[:reify]
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
    def initialize(data,context,opts={})
      super(context,opts)
      return if opts[:reify]
      case data[:type]
        when :imported_collection then initialize__imported_collection(data)
        else raise Error.new("unexpeced link def type (#{data[:type]})")
      end
    end
  end

  class LinkDefMeta < MetaObject
    include LinkDefMetaMixin
   private
    def object_attributes()
      [:possible_links]
    end

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
    private
    def object_attributes()
      [:attribute_mappings]
    end
  end

  class LinkDefAttributeMappingMeta  < MetaObject
    def initialize(data,context,opts={})
      super(context,opts)
      return if opts[:reify]
      self[:include] = true if data[:include]
      self[:output] = data[:output]
      self[:input] = data[:input]
    end
  end


  class AttributeMeta < MetaObject
    def initialize(parse_struct,context,opts={})
      super(context,opts)
      return if opts[:reify]
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

    def reset_hash_key_and_name_fields(new_key_x)
      new_key = set_hash_key(new_key_x)
      set_field_name(new_key)
      set_label(new_key)
      set_external_ref_name(new_key)
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
      set_field_name(name)
      set_label(name)
      self[:label] = t(name) 
      self[:description] = unknown
      self[:type] = t("string") #default taht can be overriten
      var_default = nil
      if default = attr_ps[:default]
        if default.set_default_value?()
          self[:type] = t(default.data_type)
          var_default = default.contains_variable?()
          self[:default_info] = var_default ? unknown : t(default.to_s) 
        end
      end
      if var_default
        self[:required] = t(false)
      else
        self[:required] = (attr_ps.has_key?(:required) ? nailed(attr_ps[:required]) : unknown)
        self[:include] = true if attr_ps[:required]
      end

      type = "#{config_agent_type}_attribute"
      ext_ref = create_external_ref(attr_ps[:name],type)
      ext_ref.merge!("default_variable" => default.to_s) if var_default
      self[:external_ref] = nailed(ext_ref)
    end

    def set_field_name(name)
      self[:field_name] = t(name)
    end
    
    def set_label(label)
      self[:label] = t(label)
    end

    def set_external_ref_name(name)
      self[:external_ref] && self[:external_ref]["name"] = name
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

