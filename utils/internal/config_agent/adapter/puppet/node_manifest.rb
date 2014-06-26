module DTK; class ConfigAgent; module Adapter
  class Puppet
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
      # this configuration switch is whether anchors are used in generating teh 'class wrapper' for putting definitions in stages
      UseAnchorsForClassWrapper = false
      # TODO: best practice would be to use anchors so internal resources dont 'fall out', but to use this requires that stdlib is always include
      # so turning off now
      def use_anchors_for_class_wrappers?()
        UseAnchorsForClassWrapper
      end

      # stage_ids can be of form
      #[[cmp_id1,cmp_id2],[cmp_id3,cmp_id4,cmp_id5]]
      # or
      ##[[[cmp_id1],[cmp_id2]],[[cmp_id3,cmp_id4],[cmp_id5]]]
      # In both cases teh top leevl shows sepearte puppet runs
      # in the first case for each puppet run, each comp wil be in sepearte puppet stage
      # in case 2, extra grouping shows how components are grouped into puppet stages
      def generate_with_stages(cmps_with_attrs,assembly_attrs,stages_ids)
        stages_ids.map do |stage_ids_exec_block|
          exec_block = Array.new
          add_default_extlookup_config!(exec_block)
          add_assembly_attributes!(exec_block,assembly_attrs||[])
          exec_block << generate_stage_statements(stage_ids_exec_block.size)
          stage_ids_exec_block.each_with_index do |stage_ids, i|
            stage = i+1
            exec_block << " " #space between stages
            puppet_stage = PuppetStage.new(stage,@import_statement_modules)
            Array(stage_ids).each do |cmp_id| 
              cmp_with_attrs = cmps_with_attrs.find { |cmp| cmp["id"] == cmp_id }       
              puppet_stage.generate_manifest!(cmp_with_attrs)
            end
            puppet_stage.add_lines_for_stage!(exec_block)
          end

          if attr_val_stmts = get_attr_val_statements(cmps_with_attrs)
            exec_block += attr_val_stmts
          end
          exec_block
        end
      end      

      def generate_with_total_ordering(cmps_with_attrs,assembly_attrs=nil)
        lines = Array.new
        add_default_extlookup_config!(lines)
        add_assembly_attributes!(lines,assembly_attrs||[])
        lines << generate_stage_statements(cmps_with_attrs.size)
        cmps_with_attrs.each_with_index do |cmp_with_attrs,i|
          stage = i+1
          lines << " " #space between stages
          PuppetStage.new(stage,@import_statement_modules).generate_manifest!(cmp_with_attrs).add_lines_for_stage!(lines)
        end

        if attr_val_stmts = get_attr_val_statements(cmps_with_attrs)
          lines += attr_val_stmts
        end
        [lines] #putting lines in [] because pupept apply agent is just lookingfor multiple invocations form
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
            # TODO: see if need \" and quote form
            attr_str_array = attrs.map{|k,v|"#{k} => #{process_val(v)}"} + [stage_assign()]
            attr_str = attr_str_array.join(", ")
            @class_lines << "class {\"#{cmp}\": #{attr_str}}"
           when "definition"
            unless defn_cmp = cmp_with_attrs["name"]
              raise ErrorUsage.new("No definition name") 
            end

            name_attr = nil
            attr_str_array = attrs.map do |k,v|
              if k == "name"
                name_attr = quote_form(v)
                nil
              else
                "#{k} => #{process_val(v)}"
              end
            end.compact
            unless name_attr
              raise ErrorUsage.new("No name attribute for definition component (#{defn_cmp})") 
            end

            if use_anchors_for_class_wrappers?()
              attr_str_array << "require => #{anchor_ref(:begin)}"
              attr_str_array << "before => #{anchor_ref(:end)}"
            end
            attr_str = attr_str_array.join(", ")
            if imp_stmt = needs_import_statement?(defn_cmp,module_name)
              @def_lines << imp_stmt
            end
            @def_lines << "#{defn_cmp} {#{name_attr}: #{attr_str}}"
          end
          self
        end

       private
        def add_definition_lines!(ret)
          unless @def_lines.empty?()
            # putting def in class because defs cannot go in stages
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

        # removes imported collections and puts them on global array
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
          # TODO: keeping in, in case we decide to do check for import; use of imports are now considered violating Puppet best practices
          # if wanted to actual check would need to know what manifest files are present
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
            # only include if the dynamic attribute is connected
            # TODO: this is mechanism used to avoid duplicate r8::export_variable declarations: making sure downstream that
            # definitions cannot be connected
            if dyn_attr[:is_connected]
              if dyn_attr[:type] == "default_variable"
                qualified_var = "#{cmp_with_attrs["name"]}::#{dyn_attr[:name]}"
                ret << "r8::export_variable{'#{qualified_var}' :}"
              end
            end
          end
        end
        ret.empty? ? nil : ret
      end

      
      def process_val(val)
        # a guarded val
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
end; end; end


