module DTK
  class Attribute
    module PrintFormMixin
      def print_form(opts=Opts.new)
        update_object!(*PrintForm::UpdateCols)
        #TODO: handle complex attributes better and omit derived attributes; may also indicate whether there is an override
        display_name_prefix = opts[:display_name_prefix]||PrintForm.display_name_prefix(self,opts)
        display_name = "#{display_name_prefix}#{self[:display_name]}"
        datatype =
          case self[:data_type]
          when "integer" then "integer"
          when "boolean" then "boolean"
          else "string"
          end
        value = info_about_attr_value(self[:attribute_value])
        attr_info = {
          :display_name => display_name, 
          :datatype => datatype,
          :description => self[:description]||self[:display_name]
        }
        attr_info.merge!(:value => value) if value
        hash_subset(*PrintForm::UnchangedDisplayCols).merge(attr_info)
      end
    end

    class PrintForm
      UnchangedDisplayCols = [:id,:required]
      UpdateCols = UnchangedDisplayCols + [:description,:display_name,:data_type,:value_derived,:value_asserted]

      #TODO: put in as option format style
      def self.display_name_prefix(aug_attr,opts=Opts.new)
        new(aug_attr,opts[:level]).display_name_prefix()
      end

      def display_name_prefix()
        case @level
         when :assembly
           ""
         when :node
           "node[#{node[:display_name]}]/"
         when :component
          "node[#{node[:display_name]}]/cmp[#{component.display_name_print_form()}]/"
        end
      end

     private
      def initialize(aug_attr,level=nil)
        @aug_attr = aug_attr #needs to be done first
        @level = level||find_level()
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
