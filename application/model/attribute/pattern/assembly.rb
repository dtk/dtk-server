module DTK; class Attribute
  class Pattern
    class Assembly < self
      r8_nested_require('assembly','link')

      def self.create(attr_term,assembly,opts={})
        # considering attribute id to belong to any format so processing here
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
        def self.create(attr_term,_opts={})
          tokens = attr_term.split("/")
          case tokens.size
            when 1
              Type::AssemblyLevel.new(t(:attribute,tokens[0]))
            when 2
              Type::NodeLevel.new("#{t(:node,tokens[0])}/#{t(:attribute,tokens[1])}")
            else
              # handling in a way that can correctly parse the case where have node/cmp_type[title]/attr and title can have '/'
              # This needs to be coorinated with ComponentTitle.parse_component_display_name
              node_part = tokens.shift
              attr_part = tokens.pop
              cmp_part = tokens.join('/')
              Type::ComponentLevel.new("#{t(:node,node_part)}/#{t(:component,cmp_part)}/#{t(:attribute,attr_part)}")
          end
        end

        private

        def self.t(type,term)
          Pattern::Term.canonical_form(type,term)
        end
      end

      class CanonicalForm
        def self.create(attr_term,_opts={})
          # can be an assembly, node or component level attribute
          if attr_term =~ /^attribute/
            Type::AssemblyLevel.new(attr_term)
          elsif attr_term  =~ /^node[^\/]*\/component/
            Type::ComponentLevel.new(attr_term)
          elsif attr_term  =~ /^node[^\/]*\/attribute/
            Type::NodeLevel.new(attr_term)
          else
            raise ErrorUsage::Parsing::Term.new(attr_term)
          end
        end
      end
    end
  end
end; end
