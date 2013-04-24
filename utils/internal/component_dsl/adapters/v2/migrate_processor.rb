module DTK; class ComponentDSL; class V2
  class MigrateProcessor
    def initialize(version,config_agent_type,module_name,old_version_hash)
      @module_name = module_name
      @old_version_hash = old_version_hash
      @version = version
      @module_type = module_type(config_agent_type)
    end
    def generate_new_version_hash()
      ret = PrettyPrintHash.new
      ret["module"] = @module_name
      ret["dsl_version"] = @version
      ret["module_type"] = @module_type
      cmps = ret["components"] = PrettyPrintHash.new
      @old_version_hash.each do |cmp_ref,cmp_info|
        cmps.merge!(strip_module_name(cmp_ref)=> migrate(:component,cmp_ref,cmp_info))
      end
      ret
    end
   private
    def module_type(config_agent_type)
      case config_agent_type
        when :puppet then "puppet_module"
        when :chef then "chef_module"
        else raise Error.new("Unexepected config_agent_type (#{config_agent_type})")
      end
    end

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
            val = CustomFn.const_get(type.to_s.capitalize).send(proc_vars[:custom_fn].to_sym,val)
          elsif proc_vars[:migrate_type]
            if proc_vars[:has_ref]
              ref = val.keys.first
              val = {ref => migrate(proc_vars[:migrate_type],ref,val.keys.first)}
            else
              val = migrate(proc_vars[:migrate_type],nil,val)
            end
          end

          next if proc_vars[:skip_if_nil] and val.nil?

          new_key = proc_vars[:new_key]
          if ret[new_key].nil?
            ret[new_key] = val
          else
            if ret[new_key].kind_of?(Array)
              if val.kind_of?(Array)
                ret[new_key] += val
              else
                ret[new_key] << val
              end
            elsif ret[new_key].kind_of?(Hash) and val.kind_of?(Hash)
              ret[new_key].merge!(val)
            else
              raise Error.new("Need to 'merge' different attributes, but unexpected form")
            end
          end
        end
      end

      rest_attrs = (assigns.keys - (AttrOmit[type]||[])) - AttrProcessed[type]
      unless rest_attrs.empty?
        raise Error.new("feature_component_dsl_v2: TODO: not yet implemented component keys (#{rest_attrs.join(",")})")
      end
#      rest_attrs.each{|k|ret[k] = assigns[k] if assigns[k]}
      ret
    end

    def strip_module_name(cmp_ref)
      cmp_ref.gsub(Regexp.new("^#{@module_name}__"),"")
    end

    def raise_error_if_treated(type,ref,assigns)
      case type
      when :component
        unless ref == assigns["display_name"] and ref == assigns["component_type"]
          raise Error.new("assumption is that component (#{ref}), display_name (#{assigns["display_name"]}), and component_type (#{ref == assigns["component_type"]}) are all equal")
        end
      end
    end

    ### aux methods

    def ret_processing_vars(attr_proc_info)
      ret = Hash.new
       if attr_proc_info.kind_of?(Hash)
         ret[:key] = attr_proc_info.keys.first.to_s
         info = attr_proc_info.values.first
         ret.merge!(Aux::hash_subset(info,[:new_key,:type,:custom_fn,:has_ref,:skip_if_nil]))
         ret[:new_key] ||= ret[:key]
         ret[:new_key] = ret[:new_key].to_s
        else
         ret[:new_key] = ret[:key] = attr_proc_info.to_s
       end
      ret
    end

    AttrOrdered = { 
      :component =>
      [
       :description,
       {:external_ref => {:custom_fn => :external_ref}},
       {:basic_type => {:custom_fn => :type, :new_key => :type, :skip_if_nil => true}},
       {:ui => {:custom_fn => :ui}},
       {:attribute => {:new_key => :attributes,:custom_fn => :attributes}},
       {:dependency => {:new_key => :depends_on,:custom_fn => :requires_components}},
       {:component_order => {:new_key => :after,:custom_fn => :after_components}},
       {:external_link_defs => {:new_key => :depends_on, :custom_fn => :external_link_defs}}
      ]
    }
    AttrOmit = {
      :component => %w{display_name component_type version only_one_per_node}
    }

    AttrProcessed = AttrOrdered.inject(Hash.new) do |h,(type,attrs_info)|
      proc_attrs = attrs_info.map do |attr_info|
        (attr_info.kind_of?(Hash) ? attr_info.keys.first.to_s : attr_info.to_s)
      end
      h.merge(type => proc_attrs)
    end
    TypesTreated = AttrOrdered.keys

    ModuleComponentSeperator  = "::"

    class CustomFn
      def self.qualified_component_ref(cmp_ref)
        cmp_ref.gsub(/__/,ModuleComponentSeperator)
      end

      def self.component_part(qual_cmp_ref)
        if qual_cmp_ref =~ Regexp.new("#{ModuleComponentSeperator}(.+$)")
          $1
        else
          qual_cmp_ref
        end
      end

      def self.map_in_array_form(assigns,&block)
        ret_singleton_form = Array.new
        ndx_ret = Hash.new
        assigns.each do |ref,info|
          el = block.call(ref,info)
          if el.size == 1 
            key = el.keys.first
            val = el.values.first
            if ndx_ret[key]
              if ndx_ret[key][:single_el]
                ndx_ret[key] = {:els => [ndx_ret[key][:els],val],:single_el => false} 
              else
                ndx_ret[key][:els] << val
              end
            else
              ndx_ret[key] = {:els => val,:single_el => true}
            end
          else
            ret_singleton_form << el
          end
        end
        ret_singleton_form + ndx_ret.map{|k,v|{k => v[:els]}}
      end

      class Component < self
        def self.only_one_per_node(ext_ref_assigns)
          type = ext_ref_assigns["type"]
          ["puppet_definition"].include?(type) ? true : nil
        end

        def self.type(basic_type)
          #omit default 'service'
          (basic_type == "service") ? nil : basic_type
        end

        def self.external_ref(ext_ref_assigns)
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

        def self.attributes(attrs_assigns)
          #TODO: may sort alphabetically (same for othter lists)
          attrs_assigns.inject(PrettyPrintHash.new) do |h,(attr,attr_info)|
            h.merge(attr => Attribute.attribute(attr,attr_info))
          end
        end

        def self.external_link_defs(external_link_defs)
          external_link_defs.map{|external_link_def|LinkDef.external_link_def(external_link_def)}
        end

        def self.ui(assigns)
          ui__single_png(assigns)||assigns
        end

        def self.ui__single_png(assigns)
          return unless assigns.size == 1 and assigns.keys.first == "images"
      
          image_assigns = assigns.values.first
          return unless image_assigns.keys.sort == ["display","tiny","tnail"]
          
          return unless image_assigns["tiny"].empty?
          return unless image_assigns["tnail"] == image_assigns["display"]
          {"image_icon" => image_assigns["tnail"]}
        end
      
        def self.requires_components(deps_assigns)
          map_in_array_form(deps_assigns){|ref,dep_assign|Constraint.requires_component(ref,dep_assign)}
        end

        def self.after_components(assigns)
          map_in_array_form(assigns){|ref,cmp_order_rel| Constraint.after_component(ref,cmp_order_rel)}
        end
      end
      
      class Attribute < self
        def self.attribute(attr,attr_info)
          ret = PrettyPrintHash.new
          %w{description}.each{|k|ret[k] = attr_info[k] if attr_info[k]}
          type = type(attr_info["data_type"],attr_info["semantic_type"])
          ret["type"] = type if type
          ret["default"] = attr_info["value_asserted"] if attr_info["value_asserted"]
          ret["required"] = true if attr_info["required"]
          ret["dynamic"] = true if attr_info["dynamic"]
          external_ref = external_ref(attr,attr_info["external_ref"])
          ret["external_ref"] = external_ref if external_ref
          ret
        end

        def self.type(data_type,semantic_type)
          ret = nil
          if semantic_type
            unless semantic_type.kind_of?(Hash) and semantic_type.size == 1 and semantic_type.keys.first == ":array"
              Log.error("Ignoring because unexpected semantic type (#{semantic_type})")
            else
              ret = "array(#{semantic_type.values.first})"
            end
          end
          ret ||= data_type
          ret
        end

        def self.external_ref(attr,ext_ref_assigns)
          ret = PrettyPrintHash.new
          key = type = ext_ref_assigns["type"]
          val_attr = nil
          override_val = nil
          case type
          when "puppet_attribute"
            val_attr = "path"
            override_val = (ext_ref_assigns["path"] =~ /node\[[^\]]+\]\[([^\]]+)/; $1)
          else
            raise Error.new("Do not treat external ref type: #{type}")
          end
          key_val = override_val||ext_ref_assigns[val_attr]
          #ignore if key_val is same as attribute
          unless key_val === attr
            ret[key] = override_val||ext_ref_assigns[val_attr]
          end

          #get any other attributes in ext_ref
          (ext_ref_assigns.keys - ["type",val_attr]).each{|k|ret[k] = ext_ref_assigns[k]}
          ret.empty? ? nil : ret
        end
      end

      class LinkDef < self
        def self.external_link_def(assigns)
          content = PrettyPrintHash.new
          pls = assigns["possible_links"]
          unless pls.size == 1
            raise Error.new("feature_component_dsl_v2: TODO: not implemented yet when multiple possible links")
          end

          choice_info = choice_info(pls.first)
          ref = choice_info[:remote_cmp_ref]
          unless component_part(ref) == assigns["type"]
            content["relation_name"] = assigns["type"]
          end
          content["location"] = "remote"
          content["required"] = false if (!assigns["required"].nil?) and not assigns["required"]
          content["attribute_mappings"] = choice_info[:attribute_mappings]
          {ref => content}
        end

        def self.choice_info(assigns)
          remote_cmp_ref = qualified_component_ref(assigns.keys.first)
          info = assigns.values.first
          unless info.keys == ["attribute_mappings"]
            raise Error.new("feature_component_dsl_v2: TODO: not implemented yet when possibles links has keys (#{info.keys.join(",")})")
          end
          attribute_mappings = info["attribute_mappings"].map{|am|attribute_mapping(am,remote_cmp_ref)}
          {:remote_cmp_ref => remote_cmp_ref,:attribute_mappings => attribute_mappings}
        end

        def self.attribute_mapping(assigns,remote_cmp_ref)
          unless assigns.kind_of?(Hash) and assigns.size == 1
            raise Error.new("Unexpected form for attribute mapping (#{assigns.inspect})")
          end
          left_attr, dir = attribute_mapping_attr_info(assigns.keys.first,remote_cmp_ref)
          right_attr = attribute_mapping_attr_info(assigns.values.first)

          if dir == :output_to_input
            "$#{left_attr} -> #{right_attr}"
          else
            "#{left_attr} <- $#{right_attr}"
          end
        end

        #if remote_cmp_ref non-null returns [attr_ref,dir], otherwise just returns attr_ref
        def self.attribute_mapping_attr_info(var,remote_cmp_ref=nil)
          dir = nil
          attr_ref = nil
          parts = (var =~ /(^[^.]+)\.(.+$)/; [$1,$2])
          case parts[0]
           when ":remote_node",":local_node" 
            attr_ref = ["node",parts[1].gsub(/host_addresses_ipv4\.0/,"host_address")].join('.')
            dir = (remote_cmp_ref && (parts[0] == ":remote_node" ? :output_to_input : :input_to_output))
           else
            attr_ref = parts[1]
            if remote_cmp_ref
              dir = (remote_cmp_ref == qualified_component_ref(parts[0]).gsub(/^:/,"") ? :output_to_input : :input_to_output) 
            end
          end
          dir ? [attr_ref,dir] : attr_ref
        end
      end

      class Constraint < self
        def self.requires_component(ref,dep_assign)
          ret = nil
          return ret unless dep_assign["type"] == "component"
          return ret unless filter = (dep_assign["search_pattern"]||{})[":filter"]
          return ret unless filter[0] == ":eq" and filter[1] == ":component_type"
          qualified_component_ref(filter[2])
        end

        def self.after_component(ref,cmp_order_rel)
          if cmp_order_rel.keys == ["after"]
            qualified_component_ref(cmp_order_rel["after"])
          else
            "feature_component_dsl_v2: TODO: not implemented yet treating component_order relation (#{{ref => cmp_order_rel}.inspect})"
          end
        end

      end
    end
  end
end; end; end
