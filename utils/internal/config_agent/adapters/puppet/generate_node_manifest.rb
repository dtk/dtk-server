module XYZ
  module PuppetGenerateNodeManifest
    class NodeManifest
      def initialize()
        @import_statement_modules = Array.new
      end

      def generate(cmps_with_attrs)
        ret = Array.new
        cmps_with_attrs.each_with_index do |cmp_with_attrs,i|
          stage = i+1
          module_name = cmp_with_attrs["module_name"]
          ret << "stage{#{quote_form(stage)} :}"
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
        size = cmps_with_attrs.size
        if size > 1
          ordering_statement = (1..cmps_with_attrs.size).map{|s|"Stage[#{s.to_s}]"}.join(" -> ")
          ret << ordering_statement
        end

        if attr_val_stmts = get_attr_val_statements(cmps_with_attrs)
          ret += attr_val_stmts
        end
        ret
      end
     private
      def needs_import_statement?(cmp_or_def,module_name)
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
          when "imported_collection"
            add_imported_collection(cmp_name,attr_name,val,{"resource_type" => attr_info["resource_type"], "import_coll_query" =>  attr_info["import_coll_query"]})
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

      def process_dynamic_attributes?(cmps_with_attrs)
        ret = Array.new
        cmps_with_attrs.each do |cmp_with_attrs|
          cmp_name = cmp_with_attrs["name"]
          dyn_attrs = cmp_with_attrs["dynamic_attributes"]
          if dyn_attrs and not dyn_attrs.empty?
            resource_ref = resource_ref(cmp_with_attrs)
            dyn_attrs.each do |dyn_attr|
              if el = dynamic_attr_response_el(cmp_name,dyn_attr)
                ret << el
              end
            end
          end
        end
        ret.empty? ? nil : ret
      end
      def dynamic_attr_response_el(cmp_name,dyn_attr)
        ret = nil
        val = 
          if dyn_attr[:type] == "exported_resource" 
            dynamic_attr_response_el__exported_resource(cmp_name,dyn_attr)
          elsif dyn_attr[:type] == "default_variable"
            dynamic_attr_response_el__default_attribute(cmp_name,dyn_attr)
          else #assumption only three types: "exported_resource", "default_attribute, (and other can by "dynamic")
            dynamic_attr_response_el__dynamic(cmp_name,dyn_attr)
          end
        if val
          ret = {
            :component_name => cmp_name,
            :attribute_name => dyn_attr[:name],
            :attribute_id => dyn_attr[:id],
            :attribute_val => val
          }
        end
        ret
      end

      def dynamic_attr_response_el__exported_resource(cmp_name,dyn_attr)
        ret = nil 
        if cmp_exp_rscs = exported_resources(cmp_name)
          cmp_exp_rscs.each do |title,val|
            return val if exp_rsc_match(title,dyn_attr[:title_with_vars])
          end
        else
          @log.info("no exported resources set for component #{cmp_name}")
        end
        ret
      end

      #TODO: more sophistiacted would take var bindings
      def exp_rsc_match(title,title_with_vars)
        regexp_str = regexp_string(title_with_vars)
        @log.info("debug: regexp_str = #{regexp_str}")
        title =~ Regexp.new("^#{regexp_str}$") if regexp_str
      end

      def regexp_string(title_with_vars)
        if title_with_vars.kind_of?(Array)
          case title_with_vars.first 
          when "variable" then ".+"
          when "fn" then regexp_string__when_op(title_with_vars)
          else
            @log.info("unexpected first element in title with vars (#{title_with_vars.first})")
            nil
          end
        else
          title_with_vars.gsub(".","\\.")
        end
      end

      def regexp_string__when_op(title_with_vars)
        unless title_with_vars[1] == "concat"
          @log.info("not treating operation (#{title_with_vars[1]})")
          return nil
        end
        title_with_vars[2..title_with_vars.size-1].map do |x|
          return nil unless re = regexp_string(x)
          re
        end.join("")
      end

      def dynamic_attr_response_el__dynamic(cmp_name,dyn_attr)
        ret = nil
        attr_name = dyn_attr[:name]
        filepath = (exported_files(cmp_name)||{})[attr_name]
        #TODO; legacy; remove when deprecate 
        filepath ||= "/tmp/#{cmp_name.gsub(/::/,".")}.#{attr_name}"
        begin
          val = File.open(filepath){|f|f.read}.chomp
          ret = val unless val.empty?
         rescue Exception
        end
        ret
      end

      def dynamic_attr_response_el__default_attribute(cmp_name,dyn_attr)
        ret = nil
        unless cmp_exp_vars = exported_variables(cmp_name)
          @log.info("no exported varaibles for component #{cmp_name}")
          return ret
        end
        
        attr_name = dyn_attr[:name]
        unless cmp_exp_vars.has_key?(attr_name)
          @log.info("no exported variable entry for component #{cmp_name}, attribute #{dyn_attr[:name]})")
          return ret
        end

        cmp_exp_vars[attr_name]
      end

      def clean_state()
        [:exported_resources, :exported_variables, :report_status, :imported_collections].each do |k|
          Thread.current[k] = nil if Thread.current.keys.include?(k)
        end
      end
      def exported_resources(cmp_name)
        (Thread.current[:exported_resources]||{})[cmp_name]
      end
      def exported_variables(cmp_name)
        (Thread.current[:exported_variables]||{})[cmp_name]
      end
      def exported_files(cmp_name)
        (Thread.current[:exported_files]||{})[cmp_name]
      end
      def add_imported_collection(cmp_name,attr_name,val,context={})
        p = (Thread.current[:imported_collections] ||= Hash.new)[cmp_name] ||= Hash.new
        p[attr_name] = {"value" => val}.merge(context)
      end

      def resource_ref(cmp_with_attrs)
        case cmp_with_attrs["component_type"]
        when "class"
          "Class[#{quote_form(cmp_with_attrs["name"])}]"
        when "definition"
          defn = cmp_with_attrs["name"]
          def_name = (cmp_with_attrs["attributes"].find{|k,v|k == "name"}||[]).last
          raise "Cannot find the name associated with definition #{defn}" unless def_name
          "#{capitalize_resource_name(defn)}[#{quote_form(def_name)}]"
        else
          raise "Reference to type #{cmp_with_attrs["component_type"]} not treated"
        end
      end

      def self.capitalize_resource_name(name)
        name.split('::').map{|p|p.capitalize}.join("::")
      end
      def capitalize_resource_name(name)
        self.class.capitalize_resource_name(name)
      end

      DynamicVarDefName = "r8_dynamic_vars::set_var"
      DynamicVarDefNameRN = capitalize_resource_name(DynamicVarDefName)

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
