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
        ret = Array.new
        nodes = ret_matching_nodes(assembly_idh)
        return ret if nodes.empty?
pp nodes
      end
    end

   private 
    def initialize(pattern)
      @pattern = pattern
    end
    attr_reader :pattern

    def ret_matching_nodes(assembly_idh)
      node_filter = ret_filter(pattern)
      if node_filter == "*"
        sp_hash = {
          :cols => [:display_name,:id],
          :filter => [:eq, :assembly_id, assembly_idh.get_id()]
        }
        Model.get_objs(assembly_idh.createMH(:node),sp_hash)
      else
        raise ErrorNotImplementedYet.new()
      end
    end

    def ret_filter(fragment)
      if fragment =~ /[a-z]\[([^\]]+)\]/
        $1
      else
        "*" #without qaulification means all
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

