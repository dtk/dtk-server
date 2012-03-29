#TODO: wil eventually persist so can save and reuse; wil put under probablty project
module XYZ
  class AssemblyAttributePattern
    def self.create(pattern)
      #can be an assembly, node or component level attribute
      if pattern =~ /^attribute/
        AssemblyLevel.new(pattern)
      elsif pattern  =~ /^node[^\/]*\/component/
        ComponentLevel.new(pattern)
      elsif pattern  =~ /^node[^\/]*\/attribute/
        NodeLevel.new(pattern)
      else
        raise ErrorParse.new(pattern)
      end
    end
    
    def ret_attribute_idhs(assembly_idh)
      raise Error.new("Should be overwritten")
    end
    
    class ComponentLevel < AssemblyAttributePattern
      def ret_attribute_idhs(assembly_idh)
      end
    end

   private 
    def initialize(pattern)
      @pattern = pattern
    end
    attr_reader :pattern

    def ret_node_filter()
      if pattern  =~ /^node([^\/])*\//
        node_filter = $1
        if node_filter == "[*]"
          :all
        else
          raise ErrorNotImplementedYet.new()
        end
      end
    end

    class ErrorParse < Error
      def initilize(pattern)
        super("Cannot parse #{pattern}")
      end
    end
    class ErrorNotImplementedYet < Error
      def initilize(pattern)
        super("not implemented yet")
      end
    end
  end
end
