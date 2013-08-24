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

      class Simple
        def self.create(attr_term,opts={})
          split_term = attr_term.split("/")
          if split_term.size > 3 
            raise ErrorParse.new(attr_term)
          end
          case split_term.size          
            when 1 
              Type::AssemblyLevel.new("attribute[#{split_term[0]}]")
            when 2 
              Type::NodeLevel.new("node[#{split_term[0]}]/attribute[#{split_term[1]}]")
            when 3 
              Type::ComponentLevel.new("node[#{split_term[0]}]/component[#{split_term[1]}]/attribute[#{split_term[2]}]")
          end
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
