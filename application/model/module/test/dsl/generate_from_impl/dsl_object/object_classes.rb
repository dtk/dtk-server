# TODO: better sepearte parts that are where creating refinement has and parts for rendering in dtk  dsl vrsion specfic form
module DTK; class TestDSL
  class GenerateFromImpl
    class DSLObject
      class Module < self
        def initialize(top_parse_struct,context,opts={})
          super(context,opts)
          return if opts[:reify]
          context.each{|k,v|self[k] = v}
          self[:components] = DSLArray.new
          top_parse_struct.each_component do |component_ps|
            self[:components] << create(:component,component_ps)
          end
          process_imported_resources()
        end

        def render_hash_form(opts={})
          ret = RenderHash.new
          ret.set_unless_nil("module",module_name?())
          ret.set_unless_nil("dsl_version",TestDSL.version(integer_version()))
          ret.set_unless_nil("module_type",module_type?())
          self[:components].each_element(:skip_required_is_false => true) do |cmp|
            hash_key = render_cmp_ref(cmp.hash_key)
            unless (ScaffoldingStrategy[:ignore_components]||[]).include?(hash_key)
              add_component!(ret,hash_key,cmp.render_hash_form(opts))
            end
          end
          set_include_modules!(ret,opts)
          ret
        end

        def render_to_file(file,format)
        end

       private
        def object_attributes()
          [:components]
        end

        def set_include_modules!(ret,opts={})
        end

        def process_imported_resources()
          # first get all the exported resources and imported resources
          # TODO: more efficient to store these in first phase
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
          # get all teh matches
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

          # create link defs
          matches.each do |match|
            if link_def = create(:link_def,match)
              (match[:attr_imp_coll].parent[:link_defs] ||= DSLArray.new) << link_def
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

        # for render_hash
        def module_name?()
          nil
        end

        def module_type?()
          nil
        end

        def render_cmp_ref(hash_key)
          hash_key
        end
      end

      class Component < self
        def initialize(component_ps,context,opts={})
          super(context,opts)
          return if opts[:reify]
          processed_name = component_ps[:name]
          # if qualified name make sure matches module name
          if processed_name =~ /(^[^:]+)::(.+$)/
            prefix = $1
            unqual_name = $2
            unless prefix == module_name
              raise ErrorUsage::Parsing.new("Test (#{processed_name}) has a module name unequal to the base module name (#{module_name})")
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
          if component_ps.has_key?(:only_one_per_node)
            self[:only_one_per_node] = t(component_ps[:only_one_per_node])
          end
          self[:dependencies] = dependencies unless dependencies.empty?
          set_attributes(component_ps)
        end

       private
        def object_attributes()
          [:attributes,:dependencies,:link_defs]
        end
        def dependencies(component_ps)
          ret = DSLArray.new
          ret += find_foreign_resource_names(component_ps).map do |name|
            create(:dependency,{:type => :foreign_dependency, :name => name})
          end
          # TODO: may be more  dependency types
          ret
        end

        def set_attributes(component_ps)
          attr_num = 0
          self[:attributes] = DSLArray.new
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

        # for render_hash
        def display_name?()
        end
        def label?()
        end
        def basic_type?()
        end
        def type?()
        end
        def component_type?()
        end
        def only_one_per_node?()
        end

        def converted_dependencies(opts)
          nil #TODO: stub
        end

        def converted_link_defs(opts)
          return nil unless lds = self[:link_defs]
          lds.map_element(:skip_required_is_false => true){|ld|ld.render_hash_form(opts)}
        end

        def converted_attributes(opts)
          attrs = self[:attributes]
          return nil if attrs.nil? or attrs.empty?
          ret = RenderHash.new
          attrs.each_element(:skip_required_is_false => true) do |attr|
            hash_key = attr.hash_key
            ret[hash_key] = attr.render_hash_form(opts)
          end
          ret
        end
      end

      class Dependency < self
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

      # TODO: see if makes sense to handle the exported resource link defs heere while using store confif helper file to deal with attributes
      module LinkDefDSLMixin
        def initialize(data,context,opts={})
          super(context,opts)
          return if opts[:reify]
          case data[:type]
          when :imported_collection then initialize__imported_collection(data)
          else raise Error.new("unexpeced link def type (#{data[:type]})")
          end
        end
      end

      class LinkDef < self
        include LinkDefDSLMixin
       private
        def object_attributes()
          [:possible_links]
        end

        def initialize__imported_collection(data)
          self[:include] = true
          self[:required] = nailed(true)
          self[:type] = t(data[:attr_exp_rsc].parent.hash_key)
          self[:possible_links] = (DSLArray.new << create(:link_def_possible_link,data))
        end
      end

      class LinkDefPossibleLink < self
        include LinkDefDSLMixin
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

      class LinkDefAttributeMapping < self
        def initialize(data,context,opts={})
          super(context,opts)
          return if opts[:reify]
          self[:include] = true if data[:include]
          self[:output] = data[:output]
          self[:input] = data[:input]
        end
      end


      class Attribute < self
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
          self[:type] = t("string") #default that can be overriten
          var_default = nil
          if default = attr_ps[:default]
            if default.set_default_value?()
              self[:type] = t(default.data_type)
              var_default = default.contains_variable?()
              self[:default_info] = var_default ? unknown : t(default.default_value())
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

        # render hash methods
        def display_name?()
        end
      end
    end
  end
end; end
