module DTK; class ConfigAgent; module Adapter; class Puppet
  class ParseStructure
    class ParseError < ConfigAgent::ParseError
      def initialize(msg, opts = Opts.new)
        opts_parent = Opts.new
        if ast_item = opts[:ast_item]
          if line_num = ast_item.line
            opts_parent.merge!(line_num: line_num)
          end
        end
        super(msg, opts_parent)
      end
    end
  end
end; end; end; end
