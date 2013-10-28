module DTK; class Attribute
  class Pattern 
    class Assembly < self
      r8_nested_require('assembly','source')

      def self.create(attr_term,assembly,opts={})
        #considering attribute id to belong to any format so processing here
        if attr_term =~ /^[0-9]+$/
          return Type::ExplicitId.new(attr_term,assembly)
        end

        format = opts[:format]||Format::Default
        klass = 
          case format
            when :simple then Simple
            when :canonical_form then CanonicalForm
          else raise Error.new("Unexpected format (#{format})")
          end
        klass.create(attr_term,opts)
      end

      class Type < Pattern::Type
        class AssemblyLevel < self
          def attribute_idhs()
            @attributes_stack.map{|attr|attr[:attribute].id_handle()}
          end

          def set_parent_and_attributes!(assembly_idh,opts={})
            attributes = ret_matching_attributes(:component,[assembly_idh],pattern)
            #if does not exist then create the attribute if carete flag set
            #if exists and create flag exsists we just assign it new value
            if attributes.empty? and opts[:create]
              af = ret_filter(pattern,:attribute)
              #attribute must have simple form 
              unless af.kind_of?(Array) and af.size == 3 and af[0..1] == [:eq,:display_name]
                raise Error.new("cannot create new attribute from attribute pattern #{pattern}")
              end
              field_def = {"display_name" => af[2]}
              attribute_idhs = assembly_idh.create_object().create_or_modify_field_def(field_def)
              attributes = attribute_idhs.map do |idh|
                attr = idh.create_object()
                attr.update_object!(:display_name)
                attr
              end
            end
            assembly = assembly_idh.create_object()
            assembly.update_object!(:display_name)
            @attributes_stack = attributes.map do |attr| 
              {
                :assembly => assembly,
                :attribute => attr
              }
            end
            self
          end
        end
      end

      class Simple
        def self.create(attr_term,opts={})
          tokens = attr_term.split("/")
          if tokens.size > 3 
            raise ErrorParse.new(attr_term)
          end
          case tokens.size          
            when 1 
              Type::AssemblyLevel.new(t(:attribute,tokens[0]))
            when 2 
              Type::NodeLevel.new("#{t(:node,tokens[0])}/#{t(:attribute,tokens[1])}")
            when 3 
              Type::ComponentLevel.new("#{t(:node,tokens[0])}/#{t(:component,tokens[1])}/#{t(:attribute,tokens[2])}")
          end
        end
       private 
        def self.t(type,term)
          Pattern::Term.canonical_form(type,term)
        end
      end

      class CanonicalForm
        def self.create(attr_term,opts={})
          #can be an assembly, node or component level attribute
          if attr_term =~ /^attribute/
            Type::AssemblyLevel.new(attr_term)
          elsif attr_term  =~ /^node[^\/]*\/component/
            Type::ComponentLevel.new(attr_term)
          elsif attr_term  =~ /^node[^\/]*\/attribute/
            Type::NodeLevel.new(attr_term)
          else
            raise ErrorParse.new(attr_term)
          end
        end
      end
    end
  end
end; end
