module DTK; class ActionDef
  # Top class for content classes which as hash part store raw form and then have
  # insatnce attributes for the parsed form             
  class Content < Hash
    r8_nested_require('content','constant')
    r8_nested_require('content','command')

    attr_reader :commands

    def initialize(hash_content)
      super()
      replace(hash_content)
    end
    def self.parse(hash)
      new(hash).parse_and_reify!()
    end
    
    def parse_and_reify!()
      @commands = (self[Constant::Commands]||[]).map do |serialized_command|
        Command.parse(serialized_command)
      end
      self
    end
  end
end; end
