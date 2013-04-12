module XYZ
  module PuppetGenerateNodeManifest
    class NodeManifest
      def initialize()
        @import_statement_modules = Array.new
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

      def generate_with_stages(cmps_with_attrs,assembly_attrs=nil,stages_ids=nil)
        ret = Array.new
        add_default_extlookup_config!(ret)
        add_assembly_attributes!(ret,assembly_attrs||[])
        stages_ids.each_with_index do |stage_ids, i|
          stage = i+1
          ret << "stage{#{quote_form(stage)} :}"
          stage_ids.each do |cmp_id| 
            cmp_with_attrs = cmps_with_attrs.find { |cmp| cmp["id"] == cmp_id }
            ret = generate_middle_manifest(cmp_with_attrs, stage, ret)
          end
        end
        size = stages_ids.size
        if size > 1
          ordering_statement = (1..stages_ids.size).map{|s|"Stage[#{s.to_s}]"}.join(" -> ")
          ret << ordering_statement
        end

        if attr_val_stmts = get_attr_val_statements(cmps_with_attrs)
          ret += attr_val_stmts
        end
        # DEBUG SNIPPET
        require 'rubygems'
        require 'ap'
        ap "PUPPET_MANIFEST_WITH_STAGES"
        ap ret
        ret
      end      

      def generate_with_total_ordering(cmps_with_attrs,assembly_attrs=nil)
        ret = Array.new
        add_default_extlookup_config!(ret)
        add_assembly_attributes!(ret,assembly_attrs||[])
        cmps_with_attrs.each_with_index do |cmp_with_attrs,i|
          stage = i+1
          ret << "stage{#{quote_form(stage)} :}"
          ret = generate_middle_manifest(cmp_with_attrs, stage, ret)
        end
        size = cmps_with_attrs.size
        if size > 1
          ordering_statement = (1..cmps_with_attrs.size).map{|s|"Stage[#{s.to_s}]"}.join(" -> ")
          ret << ordering_statement
        end

        if attr_val_stmts = get_attr_val_statements(cmps_with_attrs)
          ret += attr_val_stmts
        end
        # DEBUG SNIPPET
        require 'rubygems'
        require 'ap'
        ap "PUPPET_MANIFEST_WITH_TOTAL_ORDERING"
        ap ret
        ret
      end

      def generate_middle_manifest(cmp_with_attrs, stage, ret)
        module_name = cmp_with_attrs["module_name"]
          attrs = process_and_return_attr_name_val_pairs(cmp_with_attrs)
          stage_assign = "stage => #{quote_form(stage)}"
          case cmp_with_attrs["component_type"]
           when "class"
            cmp = cmp_with_attrs["name"]
            raise "No component name" unless cmp
            if imp_stmt = needs_import_statement?(cmp,module_name)
              ret << imp_stmt 
            end

            #TODO: see if need \" and quote form
            attr_str_array = attrs.map{|k,v|"#{k} => #{process_val(v)}"} + [stage_assign]
            attr_str = attr_str_array.join(", ")
            ret << "class {\"#{cmp}\": #{attr_str}}"
           when "definition"
            defn = cmp_with_attrs["name"]
            raise "No definition name" unless defn
            name_attr = nil
            attr_str_array = attrs.map do |k,v|
              if k == "name"
                name_attr = quote_form(v)
                nil
              else
                "#{k} => #{process_val(v)}"
              end
            end.compact
            attr_str = attr_str_array.join(", ")
            raise "No name attribute for definition" unless name_attr
            if imp_stmt = needs_import_statement?(defn,module_name)
              ret << imp_stmt
            end
            #putting def in class because defs cannot go in stages
            class_wrapper = "stage#{stage.to_s}"
            ret << "class #{class_wrapper} {"
            ret << "#{defn} {#{name_attr}: #{attr_str}}"
            ret << "}"
            ret << "class {\"#{class_wrapper}\": #{stage_assign}}"
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

      def needs_import_statement?(cmp_or_def,module_name)
        #TODO: this needs to be refined
        return nil if cmp_or_def =~ /::/
        return nil if @import_statement_modules.include?(module_name)
        @import_statement_modules << module_name
        "import '#{module_name}'"
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
           #TODO  imported_collection not currently treated on server
 #         when "imported_collection"
#            add_imported_collection(cmp_name,attr_name,val,{"resource_type" => attr_info["resource_type"], "import_coll_query" =>  attr_info["import_coll_query"]})
          else raise "unexpected attribute type (#{attr_info["type"]})"
          end
        end
        ret
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
