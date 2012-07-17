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
    def strip_module_name(cmp_ref)
      cmp_ref.gsub(Regexp.new("^#{@module_name}__"),"")
    end
    AttrOrdered = { 
      :component =>
      [
       :description,
       {:external_ref => {:type => :external_ref}},
       :basic_type,
       {:ui => {:custom_fn => :ui}},
       {:attribute => {:key => :attributes,:custom_fn => :attributes}},
      ],
      :external_ref => 
      [
       :type
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
    
    def raise_error_if_treated(type,ref,assigns)
      case type
      when :component
        unless ref == assigns["display_name"] and ref == assigns["component_type"]
          raise Error.new("assumption is that component (#{ref}), display_name (#{assigns["display_name"]}), and component_type (#{ref == assigns["component_type"]}) are all equal")
        end
      end
    end

    def migrate(type,ref,assigns)
      unless TypesTreated.include?(type)
        raise Error.new("Migration of type (#{type}) not yet treated")
      end
      ret = PrettyPrintHash.new
      raise_error_if_treated(type,ref,assigns)
      AttrOrdered[type].each do |attr_assigns|
        key = migrate_type = custom_fn = has_ref = nil 
        if attr_assigns.kind_of?(Hash)  
          key = attr_assigns.keys.first.to_s
          info = attr_assigns.values.first
          new_key,migrate_type,custom_fn,has_ref = [:key,:type,:custom_fn,:has_ref].map{|k|info[k]} 
          new_key ||= key
          new_key = new_key.to_s
        else
          new_key = key = attr_assigns.to_s
        end

        if val = assigns[key]
          ref = nil
          if custom_fn
            val = send("migrate__#{custom_fn}".to_sym,val)
          elsif migrate_type
            if has_ref
              ref = val.keys.first
              val = {ref => migrate(migrate_type,ref,val.keys.first)}
            else
              val = migrate(migrate_type,nil,val)
            end
          end
          ret[new_key] = val
        end
      end
      rest_attrs = (assigns.keys - (AttrOmit[type]||[])) - AttrProcessed[type]
      rest_attrs.each{|k|ret[k] = assigns[k] if assigns[k]}
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
      ext_ref = attr_info["external_ref"]
      ret_ext_ref = ret["external_ref"] = PrettyPrintHash.new
      type = ret_ext_ref["type"] = ext_ref["type"]
      case type
       when "puppet_attribute"
        attr_name = (ext_ref["path"] =~ /node\[[^\]]+\]\[([^\]]+)\]/;$1)
        ret_ext_ref["attribute_name"] = attr_name
        (ret_ext_ref.keys - ["type","path"]).each{|k|ret_ext_ref[k] = ext_ref[k]}
       else
        raise Error.new("Do not treat attribute type: #{type}")
      end
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
  end
end; end
