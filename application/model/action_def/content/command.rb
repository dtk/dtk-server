module DTK; class ActionDef; class Content
  class Command
    r8_nested_require('command','syscall')
    r8_nested_require('command','file_positioning')
    # TODO: stub
    def self.parse(serialized_command)
      Syscall.parse?(serialized_command) || FiilePositioning.parse?(serialized_command) ||
        raise(Error.new("Parse Error: #{serialized_command.inspect}")) # TODO: bring in dtk model parsing parse error class
    end

    def is_syscall?()
      kind_of?(Syscall)
    end

  end
end; end; end
              
