module DTK
  class ParsingError < ErrorUsage::DSLParsing
    def self.class_of?(obj)
      Private.dsl_parsing_error?(obj)
    end
    def self.trap(&block)
      Private.trap_dsl_parsing_error(&block)
    end

    module Private
     extend ModuleParsingErrorMixin
    end

    class BadNodeReference < self
    end

    class BadComponentReference < self
    end
    
    class BadComponentLink < self
      def initialize(node_name,component_type,link_def_ref,opts={})
        super(base_msg(node_name,component_type,link_def_ref),opts[:file_path])
      end

     private 
      def base_msg(node_name,component_type,link_def_ref)
        cmp = component_print_form(component_type, :node_name => node_name)
        "Bad link (#{link_def_ref}) for component (#{cmp})"
      end
    end
  end
end
