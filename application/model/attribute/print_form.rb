module DTK
  class Attribute
    module PrintFormMixin
      def print_form(opts=Opts.new)
        update_object!(*PrintForm::UpdateCols)
        PrintForm.print_form(self,opts)
      end
    end

    class PrintForm
      def self.print_form(aug_attr,opts=Opts.new)
        new(aug_attr,opts).print_form()
      end

      def print_form()
        attr_info = {
          :display_name => "#{@display_name_prefix}#{@aug_attr[:display_name]}",
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

     private
      #TODO: put in as option format style
      def initialize(aug_attr,opts=Opts.new)
        @aug_attr = aug_attr #needs to be done first
        level = opts[:level]||find_level()
        @display_name_prefix = opts[:display_name_prefix]||display_name_prefix(level)
      end
      def self.display_name_prefix(aug_attr,opts=Opts.new)
        new(aug_attr,opts[:level]).display_name_prefix()
      end

      def display_name_prefix(level)
        case level
         when :assembly
           ""
         when :node
           "node[#{node[:display_name]}]/"
         when :component
          "node[#{node[:display_name]}]/cmp[#{component.display_name_print_form()}]/"
        end
      end

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
