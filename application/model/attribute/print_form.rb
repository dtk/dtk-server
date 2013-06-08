module DTK
  class Attribute
    module PrintFormMixin
      def print_form(opts=Opts.new)
        update_object!(*PrintForm::UpdateCols)
        PrintForm.print_form(self,opts)
      end
    end

    module PrintFormClassMixin
      def print_form(raw_attrs,opts=Opts.new)
        ret = raw_attrs.map{|a|a.print_form(opts)}
        if (opts[:detail_to_include]||[]).include?(:attribute_links)
          unless assembly = opts[:assembly]
            raise Error.new("Unexpected to have opts[:assembly] nil")
          end
          PrintForm.augment_with_attribute_links!(ret,assembly)
        end
        ret
      end

    end

    class PrintForm
      def self.print_form(aug_attr,opts=Opts.new)
        new(aug_attr,opts).print_form()
      end

      def print_form()
        attr_name = attr_name_special_processing() || attr_name_default()
        attr_info = {
          :display_name => "#{@display_name_prefix}#{attr_name}",
          :datatype => datatype_print_form(),
          :description => @aug_attr[:description]||@aug_attr[:display_name]
        }
        if value = value_print_form()
          attr_info.merge!(:value => value)
        end
        @aug_attr.hash_subset(*PrintForm::UnchangedDisplayCols).merge(attr_info)
      end
      UnchangedDisplayCols = [:id,:required]
      UpdateCols = UnchangedDisplayCols + [:description,:display_name,:data_type,:value_derived,:value_asserted]

      def self.augment_with_attribute_links!(ret,assembly)
        ndx_attr_mappings = Hash.new
        assembly.get_augmented_attribute_mappings().each do |r|
          ndx = r[:input_id]
          pntr = ndx_attr_mappings[ndx] ||= Array.new
          output_id = r[:output_id]
          unless pntr.find{|m|m[:id] == output_id}
            opts = Opts.new
            if output_index_map = r[:output_index_map]
              opts.merge!(:index_map => output_index_map)
            end
            ndx_attr_mappings[ndx] << r[:output].print_form(opts)
          end
        end
        ret.each{|r|r.merge!(:linked_to => ndx_attr_mappings[r[:id]]||[])}
        ret
      end

     private
      def initialize(aug_attr,opts=Opts.new)
        @aug_attr = aug_attr #needs to be done first
        @display_name_prefix =  opts[:display_name_prefix] || display_name_prefix(opts.slice(:format).merge(:level => opts[:level]||find_level()))
        @index_map = opts[:index_map]
      end

      def attr_name_default()
        index_map_string = (@index_map ? @index_map.inspect() : "")
        "#{@aug_attr[:display_name]}#{index_map_string}"
      end
      def attr_name_special_processing()
        if @aug_attr[:semantic_type_summary] == "host_address_ipv4" and @index_map == [0]
          "host_address"
        end
      end

      def display_name_prefix(opts=Opts.new)
        level = opts.required(:level)
        format = DisplayNamePrefixFormats[opts[:format]||:default][level]
        case level
         when :assembly
          format
         when :node
          format.gsub(/\$node/,node()[:display_name])
         when :component
          format.gsub(/\$node/,node()[:display_name]).gsub(/\$component/,component().display_name_print_form())
        end
      end

      DisplayNamePrefixFormats = {
        :default => {
          :assembly => "a:",
          :node => "$node/",
          :component => "$node/$component/"
        },
        :bracket_form => {
          :assembly => "",
          :node => "node[$node]/",
          :component => "node[$node]/cmp[$component]/"
        }
      }

      def value_print_form()
        #TODO: handle complex attributes better 
        if value = @aug_attr[:attribute_value]
          if value.kind_of?(Array)
            #value.map{|el|value_print_form(el)}
            value.inspect
          elsif value.kind_of?(Hash)
            ret = Hash.new
            value.each do |k,v|
              ret[k] = value_print_form(v)
            end
            ret
          elsif [String,Fixnum,TrueClass,FalseClass].find{|t|value.kind_of?(t)}
            value
          else
            value.inspect
          end
        end
      end

      def datatype_print_form()
        case @aug_attr[:data_type]
         when "integer" then "integer"
         when "boolean" then "boolean"
         when "json" then @aug_attr[:semantic_type_summary]||"json"
         else "string"
        end
      end

      def node()
        @aug_attr[:node]
      end
      def component()
        @aug_attr[:component]||@aug_attr[:nested_component]
      end
      def find_level()
        if node()
          component() ? :component : :node
        else
          :assembly
        end
      end
    end
  end
end
