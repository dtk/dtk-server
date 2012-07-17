module DTK; class ComponentMetaFileV2
  class MigrateProcessor
    def initialize(module_name,parent,old_version_hash)
      @module_name = module_name
      @old_version_hash = old_version_hash
      @parent = parent
    end
    def generate_new_version_hash()
      ret = PrettyPrintHash.new
      ret["module_name"] = @module_name
      ret["version"] = @parent.version()
      cmps = ret["components"] = PrettyPrintHash.new
      @old_version_hash.each do |cmp_ref,cmp_info|
        cmps.merge!(strip_module_name(cmp_ref)=> migrate(:component,cmp_ref,cmp_info))
      end
      ret
    end
   private
    def migrate(type,ref,assigns)
      unless TypesTreated.include?(type)
        raise Error.new("Migration of type (#{type}) not yet treated")
      end
      ret = PrettyPrintHash.new
      raise_error_if_treated(type,ref,assigns)
      AttrOrdered[type].each do |attr_proc_info|
        proc_vars = ret_processing_vars(attr_proc_info)

        if val = assigns[proc_vars[:key]]
          ref = nil
          if proc_vars[:custom_fn]
            val = send("migrate__#{proc_vars[:custom_fn]}".to_sym,val)
          elsif proc_vars[:migrate_type]
            if proc_vars[:has_ref]
              ref = val.keys.first
              val = {ref => migrate(proc_vars[:migrate_type],ref,val.keys.first)}
            else
              val = migrate(proc_vars[:migrate_type],nil,val)
            end
          end

          new_key = proc_vars[:new_key]
          if ret[new_key].nil?
            ret[new_key] = val
          else
            if ret[new_key].kind_of?(Array)
              ret[new_key] << val
            elsif ret[new_key].kind_of?(Hash) and val.kind_of?(Hash)
              ret[new_key].merge!(val)
            else
              raise Error.new("Need to 'merge' different attributes, but unexpected form")
            end
          end
        end
      end

      rest_attrs = (assigns.keys - (AttrOmit[type]||[])) - AttrProcessed[type]
      rest_attrs.each{|k|ret[k] = assigns[k] if assigns[k]}
      ret
    end

    AttrOrdered = { 
      :component =>
      [
       :description,
       {:external_ref => {:custom_fn => :external_ref}},
       {:basic_type => {:new_key => :type}},
       {:ui => {:custom_fn => :ui}},
       {:attribute => {:new_key => :attributes,:custom_fn => :attributes}},
       {:dependency => {:new_key => :constraints,:custom_fn => :dependencies}}
      ]
    }
    AttrOmit = {
      :component => %w{display_name component_type}
    }

    AttrProcessed = AttrOrdered.inject(Hash.new) do |h,(type,attrs_info)|
      proc_attrs = attrs_info.map do |attr_info|
        (attr_info.kind_of?(Hash) ? attr_info.keys.first.to_s : attr_info.to_s)
      end
      h.merge(type => proc_attrs)
    end
    TypesTreated = AttrOrdered.keys

    def migrate__external_ref(ext_ref_assigns)
      ret = PrettyPrintHash.new
      key = type = ext_ref_assigns["type"]
      val_attr = nil
      override_val = nil
      case type
       when "puppet_class"
        val_attr = "class_name"
       when "puppet_definition"
        val_attr = "definition_name"
       when "puppet_attribute"
        val_attr = "path"
        override_val = (ext_ref_assigns["path"] =~ /node\[[^\]]+\]\[([^\]]+)/; $1)
       else
        raise Error.new("Do not treat external ref type: #{type}")
      end
      ret[key] = override_val||ext_ref_assigns[val_attr]

      #get any other attributes in ext_ref
      (ext_ref_assigns.keys - ["type",val_attr]).each{|k|ret[k] = ext_ref_assigns[k]}
      ret
    end

    def migrate__attributes(attrs_assigns)
      #TODO: may sort alphabetically (same for othetr lists)
      attrs_assigns.inject(PrettyPrintHash.new) do |h,(attr,attr_info)|
        h.merge(attr => migrate__attribute(attr_info))
      end
    end
    def migrate__attribute(attr_info)
      ret = PrettyPrintHash.new
      %w{description data_type}.each{|k|ret[k] = attr_info[k] if attr_info[k]}
      ret["default"] = attr_info["value_asserted"] if attr_info["value_asserted"]
      ret["external_ref"] =  migrate__external_ref(attr_info["external_ref"])
      ret
    end

    def migrate__ui(assigns)
      migrate__ui__single_png(assigns)||assigns
    end
    def migrate__ui__single_png(assigns)
      return unless assigns.size == 1 and assigns.keys.first == "images"
      
      image_assigns = assigns.values.first
      return unless image_assigns.keys.sort == ["display","tiny","tnail"]
      
      return unless image_assigns["tiny"].empty?
      return unless image_assigns["tnail"] == image_assigns["display"]
      {"image_icon" => image_assigns["tnail"]}
    end

    def migrate__dependencies(deps_assigns)
      deps_assigns.map{|ref,dep_assign| migrate__dependency(ref,dep_assign)}
    end
    def migrate__dependency(ref,dep_assign)
      ret = migrate__dependency__requires(ref,dep_assign)
      unless ret
        raise Error.new("TODO: not implemented yet treating dependency (#{{ref => dep_assign}.inspect})")
      end
      ret
    end
    def migrate__dependency__requires(ref,dep_assign)
      return unless dep_assign["type"] == "component"
      return unless filter = (dep_assign["search_pattern"]||{})[":filter"]
      return unless filter[0] == ":eq" and filter[1] == ":component_type"
      require_cmp = qualified_component_ref(filter[2])
      {"requires_component" => require_cmp}
    end

    ### aux methods
    def strip_module_name(cmp_ref)
      cmp_ref.gsub(MatchesThisModuleRegexp,"")
    end

    def qualified_component_ref(cmp_ref)
      cmp_ref.gsub(/"__"/,ModuleComponentSeperator)
    end
    MatchesThisModuleRegexp = Regexp.new("^#{@module_name}__")
    ModuleComponentSeperator  = "::"

    def raise_error_if_treated(type,ref,assigns)
      case type
      when :component
        unless ref == assigns["display_name"] and ref == assigns["component_type"]
          raise Error.new("assumption is that component (#{ref}), display_name (#{assigns["display_name"]}), and component_type (#{ref == assigns["component_type"]}) are all equal")
        end
      end
    end

    def ret_processing_vars(attr_proc_info)
      ret = Hash.new
       if attr_proc_info.kind_of?(Hash)
         ret[:key] = attr_proc_info.keys.first.to_s
         info = attr_proc_info.values.first
         ret.merge!(Aux::hash_subset(info,[:new_key,:type,:custom_fn,:has_ref]))
         ret[:new_key] ||= ret[:key]
         ret[:new_key] = ret[:new_key].to_s
        else
         ret[:new_key] = ret[:key] = attr_proc_info.to_s
       end
      ret
    end
  end
end; end
