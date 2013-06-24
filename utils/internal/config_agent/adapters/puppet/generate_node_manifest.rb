module XYZ
  module PuppetGenerateNodeManifest
    class NodeManifest
      def initialize(import_statement_modules=nil)
        @import_statement_modules = import_statement_modules||Array.new
      end

      def generate(cmps_with_attrs,assembly_attrs=nil,stages_ids=nil)
        # Amar:
        # if intra node stages configured 'stages_ids' will not be nil, 
        # if stages_ids is nil use generation with total ordering (old implementation)
        if stages_ids
          generate_with_stages(cmps_with_attrs,assembly_attrs,stages_ids)
        else
          generate_with_total_ordering(cmps_with_attrs,assembly_attrs)
        end
      end

     private
      #this configuration switch is whether anchors are used in generating teh 'class wrapper' for putting definitions in stages
      UseAnchorsForClassWrapper = false
      #TODO: best practice would be to use anchors so internal resources dont 'fall out', but to use this requires that stdlib is always include
      # so turning off now
      def use_anchors_for_class_wrappers?()
        UseAnchorsForClassWrapper
      end

      def generate_with_stages(cmps_with_attrs,assembly_attrs=nil,stages_ids=nil)
        # Amar: 'ret' variable will contain list of puppet manifests, each will be one puppet call inside puppet_apply agent
        ret = Array.new  
        stages_ids.each do |stage_ids_ps|
          ret_ps = Array.new
          add_default_extlookup_config!(ret_ps)
          add_assembly_attributes!(ret_ps,assembly_attrs||[])
          ret_ps << generate_stage_statements(stage_ids_ps.size)
          stage_ids_ps.each_with_index do |stage_ids, i|
            stage = i+1
            ret_ps << " " #space between stages
            puppet_stage = PuppetStage.new(stage,@import_statement_modules)
            stage_ids.each do |cmp_id| 
              cmp_with_attrs = cmps_with_attrs.find { |cmp| cmp["id"] == cmp_id }       
              puppet_stage.generate_manifest!(cmp_with_attrs)
            end
            puppet_stage.add_lines_for_stage!(ret_ps)
          end

          if attr_val_stmts = get_attr_val_statements(cmps_with_attrs)
            ret_ps += attr_val_stmts
          end
          ret << ret_ps
        end
        
        return ret
      end      

      def generate_with_total_ordering(cmps_with_attrs,assembly_attrs=nil)
        ret = Array.new
        add_default_extlookup_config!(ret)
        add_assembly_attributes!(ret,assembly_attrs||[])
        ret << generate_stage_statements(cmps_with_attrs.size)
        cmps_with_attrs.each_with_index do |cmp_with_attrs,i|
          stage = i+1
          ret << " " #space between stages
          PuppetStage.new(stage,@import_statement_modules).generate_manifest!(cmp_with_attrs).add_lines_for_stage!(ret)
        end

        if attr_val_stmts = get_attr_val_statements(cmps_with_attrs)
          ret += attr_val_stmts
        end
        return ret
      end

      def generate_stage_statements(size)
        (1..size).map{|s|"stage{#{s.to_s}:}"}.join(" -> ")
      end

      class PuppetStage < self
        def initialize(stage,import_statement_modules)
          super(import_statement_modules)
          @stage = stage
          @class_lines = Array.new
          @def_lines = Array.new
        end

        def add_lines_for_stage!(ret)
          @class_lines.each{|line|ret << line}
          add_definition_lines!(ret)
        end

        def generate_manifest!(cmp_with_attrs)
          module_name = cmp_with_attrs["module_name"]
          attrs = process_and_return_attr_name_val_pairs(cmp_with_attrs)
          case cmp_with_attrs["component_type"]
           when "class"
            cmp = cmp_with_attrs["name"]
            raise Error.new("No component name") unless cmp
            if imp_stmt = needs_import_statement?(cmp,module_name)
              @class_lines << imp_stmt 
            end
            #TODO: see if need \" and quote form
            attr_str_array = attrs.map{|k,v|"#{k} => #{process_val(v)}"} + [stage_assign()]
            attr_str = attr_str_array.join(", ")
            @class_lines << "class {\"#{cmp}\": #{attr_str}}"
           when "definition"
            defn = cmp_with_attrs["name"]
            raise Error.new("No definition name") unless defn
            name_attr = nil
            attr_str_array = attrs.map do |k,v|
              if k == "name"
                name_attr = quote_form(v)
                nil
              else
                "#{k} => #{process_val(v)}"
              end
            end.compact
            if use_anchors_for_class_wrappers?()
              attr_str_array << "require => #{anchor_ref(:begin)}"
              attr_str_array << "before => #{anchor_ref(:end)}"
            end
            attr_str = attr_str_array.join(", ")
            raise Error.new("No name attribute for definition") unless name_attr
            if imp_stmt = needs_import_statement?(defn,module_name)
              @def_lines << imp_stmt
            end
            @def_lines << "#{defn} {#{name_attr}: #{attr_str}}"
          end
          self
        end

       private
        def add_definition_lines!(ret)
          unless @def_lines.empty?()
            #putting def in class because defs cannot go in stages
            ret << "class #{class_wrapper} {"
            if use_anchors_for_class_wrappers?()
              ret << "  #{anchor(:begin)}"
            end
            @def_lines.each{|line|ret << "  #{line}"}
            if use_anchors_for_class_wrappers?()
              ret << "  #{anchor(:end)}"
            end
            ret << "}"
            ret << "class {\"#{class_wrapper}\": #{stage_assign}}"
          end
        end

        def class_wrapper()
          "dtk_stage#{@stage.to_s}"
        end

        def stage_assign()
          "stage => #{quote_form(@stage)}"
        end

        def anchor(type)
          "anchor{#{class_wrapper}::#{type}: }"
        end
        def anchor_ref(type)
          "Anchor[#{class_wrapper}::#{type}]"
        end

        #removes imported collections and puts them on global array
        def process_and_return_attr_name_val_pairs(cmp_with_attrs)
          ret = Hash.new
          return ret unless attrs = cmp_with_attrs["attributes"]
          cmp_name = cmp_with_attrs["name"]
          attrs.each do |attr_info|
            attr_name = attr_info["name"]
            val = attr_info["value"]
            case attr_info["type"] 
             when "attribute"
              ret[attr_name] = val
            else raise Error.new("unexpected attribute type (#{attr_info["type"]})")
            end
          end
          ret
        end

        def needs_import_statement?(cmp_or_def,module_name)
          #TODO: keeping in, in case we decide to do check for import; use of imports are now considered violating Puppet best practices
          #if wanted to actual check would need to know what manifest files are present
          return nil #TODO: would put conditional in if doing checks
          ret_import_statement(module_name)
        end

        def ret_import_statement(module_name)
          @import_statement_modules << module_name
          "import '#{module_name}'"
        end

      end

      def add_default_extlookup_config!(ret)
        ret << "$extlookup_datadir = #{DefaultExtlookupDatadir}"
        ret << "$extlookup_precedence = #{DefaultExtlookupPrecedence}"
      end
      DefaultExtlookupDatadir = "'/etc/puppet/manifests/extdata'"
      DefaultExtlookupPrecedence = "['common']"

      def add_assembly_attributes!(ret,assembly_attrs)
        assembly_attrs.each do |attr|
          ret << "$#{attr['name']} = #{process_val(attr['value'])}"
        end
      end

      def get_attr_val_statements(cmps_with_attrs)
        ret = Array.new
        cmps_with_attrs.each do |cmp_with_attrs|
          (cmp_with_attrs["dynamic_attributes"]||[]).each do |dyn_attr|
            if dyn_attr[:type] == "default_variable"
              qualified_var = "#{cmp_with_attrs["name"]}::#{dyn_attr[:name]}"
              ret << "r8::export_variable{'#{qualified_var}' :}"
            end
          end
        end
        ret.empty? ? nil : ret
      end

      
      def process_val(val)
        #a guarded val
        if val.kind_of?(Hash) and val.size == 1 and val.keys.first == "__ref"
          "$#{val.values.join("::")}"
        else
          quote_form(val)
        end
      end

      def quote_form(obj)
        if obj.kind_of?(Hash) 
          "{#{obj.map{|k,v|"#{quote_form(k)} => #{quote_form(v)}"}.join(",")}}"
        elsif obj.kind_of?(Array)
          "[#{obj.map{|el|quote_form(el)}.join(",")}]"
        elsif obj.kind_of?(String)
          "\"#{obj}\""
        elsif obj.nil?
          "nil"
        else
          obj.to_s
        end
      end

    end
  end
end
