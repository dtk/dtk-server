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
        if opts.array(:detail_to_include).include?(:attribute_links)
          unless assembly = opts[:assembly]
            raise Error.new("Unexpected to have opts[:assembly] nil")
          end
          PrintForm.augment_with_attribute_links!(ret,assembly,raw_attrs)
        end
        ret
      end
    end

    module Format
      # possible valeus are [:canonical,:simple]
      Default = :simple
    end

    class PrintForm
      def self.print_form(aug_attr,opts=Opts.new)
        new(aug_attr,opts).print_form()
      end

      def print_form
        attr_name = attr_name_special_processing() || attr_name_default()

        attr_info = {
          name: attr_name,
          display_name: "#{@display_name_prefix}#{attr_name}",
          datatype: datatype_print_form(),
          description: @aug_attr[:description]||@aug_attr[:display_name]
        }
        value = value_print_form()
        unless value.nil?()
          if @truncate_attribute_value
            truncate_size = (@truncate_attribute_value.is_a?(Fixnum) ? @truncate_attribute_value : DefaultTruncateSize)
            if value.is_a?(String) && value.size > truncate_size
              value = "#{value[0..truncate_size-1]} #{TruncateSymbols}"
            end
          end
          attr_info.merge!(value: value)
        end
        @aug_attr.hash_subset(*PrintForm::UnchangedDisplayCols).merge(attr_info)
      end
      UnchangedDisplayCols = [:id,:required]
      UpdateCols = UnchangedDisplayCols + [:description,:display_name,:data_type,:value_derived,:value_asserted]
      DefaultTruncateSize = 45
      TruncateSymbols = '...'

      def self.augment_with_attribute_links!(ret,assembly,raw_attributes)
        ndx_attrs = raw_attributes.inject({}){|h,a|h.merge(a[:id] => a)}
        ndx_attr_mappings = {}
        assembly.get_augmented_attribute_mappings().each do |r|
          ndx = r[:input_id]
          pntr = ndx_attr_mappings[ndx] ||= []
          output_id = r[:output_id]
          unless pntr.find{|m|m[:id] == output_id}
            opts = Opts.new
            if output_index_map = r[:output_index_map]
              opts.merge!(index_map: output_index_map)
            end
            ndx_attr_mappings[ndx] << r[:output].print_form(opts)
          end
        end
        ret.each do |r|
          attr_id = r[:id]
          if linked_to_obj = ndx_attr_mappings[attr_id]
            r.merge!(linked_to: linked_to_obj,linked_to_display_form: linked_to_display_form(linked_to_obj))
          else
            ext_ref = (ndx_attrs[attr_id]||{})[:external_ref]||{}
            if ext_ref[:default_variable] && ext_ref[:type] == 'puppet_attribute'
              r.merge!(linked_to_display_form: LinkedToPuppetHeader) 
            end
          end
        end
        ret
      end

      private

      def initialize(aug_attr,opts=Opts.new)
        @aug_attr = aug_attr #needs to be done first
        @display_name_prefix =  opts[:display_name_prefix] || display_name_prefix(opts.slice(:format, :with_assembly_wide_node).merge(level: opts[:level]||find_level()))
        @index_map = opts[:index_map]
        @truncate_attribute_value = opts[:truncate_attribute_values]
        @raw_attribute_value = opts[:raw_attribute_value] 
        @mark_unset_required = opts[:mark_unset_required]
      end

      def self.linked_to_display_form(linked_to_obj)
        linked_to_obj.map{|r|r[:display_name]}.join(', ')
      end
      LinkedToPuppetHeader = 'external_ref(puppet_header)'

      def attr_name_default
        index_map_string = (@index_map ? @index_map.inspect() : "")
        "#{@aug_attr[:display_name]}#{index_map_string}"
      end

      def attr_name_special_processing
        if @aug_attr[:semantic_type_summary] == "host_address_ipv4" && @index_map == [0]
          "host_address"
        end
      end

      def display_name_prefix(opts=Opts.new)
        level = opts.required(:level)
        format = DisplayNamePrefixFormats[opts[:format]||Format::Default][level]
        case level
         when :assembly
          format
         when :node
          format.gsub(/\$node/,node()[:display_name])
         when :component
          node = node()
          if node[:type].eql?('assembly_wide') && !opts[:with_assembly_wide_node]
            format.gsub(/\$node\//,'').gsub(/\$component/,component().display_name_print_form())
          else
            format.gsub(/\$node/,node[:display_name]).gsub(/\$component/,component().display_name_print_form())
          end
        end
      end

      DisplayNamePrefixFormats = {
        simple: {
          assembly: "",
          node: "$node/",
          component: "$node/$component/"
        },
        canonical: {
          assembly: "",
          node: "node[$node]/",
          component: "node[$node]/cmp[$component]/"
        }
      }

      def value_print_form(opts={})
        value = (opts.key?(:nested_val) ? opts[:nested_val] : @aug_attr[:attribute_value])
        if value.nil?
          ret = 
            if opts[:nested]
              PrintValueNil
            else
              if @mark_unset_required && @aug_attr[:required]
                # dont mark as required input ports since they will be propagated
                unless @aug_attr[:is_port] && @aug_attr[:port_type_asserted] == 'input'
                  PrintValueUnsetRequired
                end
              end
            end
          return ret
        end

        if @raw_attribute_value
          return SemanticDatatype.convert_to_internal_form(@aug_attr[:semantic_data_type],value)
        end

        if value.is_a?(Array)
          "[#{value.map{|el|value_print_form(nested_val: el,nested: true)}.join(', ')}]"
          # value.inspect
        elsif value.is_a?(Hash)
          comma = ''
          internal = value.inject('') do |s,(k,val)|
            item = s + comma
            comma = ', '
            el = value_print_form(nested_val: val,nested: true)
            "#{item}#{k}=>#{el}"
          end
          "{#{internal}}"
          # value.inspect
        elsif [String,Fixnum,TrueClass,FalseClass].find{|t|value.is_a?(t)}
          value
        else
          value.inspect
        end
      end
      PrintValueUnsetRequired = '*REQUIRED*'
      PrintValueNil = 'nil'

      def datatype_print_form
        # TODO: until will populate node/os_identifier attribute with the node_template_type datatype
        if  @aug_attr[:display_name] == 'os_identifier' && @aug_attr[:node]
          return 'node_template_type'
        end
        @aug_attr[:semantic_data_type]||@aug_attr[:data_type]
      end

      def node
        @aug_attr[:node]
      end

      def component
        @aug_attr[:component]||@aug_attr[:nested_component]
      end

      def find_level
        if node()
          component() ? :component : :node
        else
          :assembly
        end
      end
    end
  end
end
