#TODO: wil eventually persist so can save and reuse; wil put under probablty project
module XYZ
  class AssemblyAttributePattern
    def self.create(pattern)
      #can be an assembly, node or component level attribute
      if pattern =~ /^[0-9]+$/
        ExplicitId.new(pattern)
      elsif pattern =~ /^attribute/
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

    class ExplicitId < self
      def ret_attribute_idhs(assembly_idh)
        [assembly_idh.createIDH(:model_name => :attribute, :id => id())]
      end
     private
      def id()
        @pattern
      end
    end

    class AssemblyLevel < self
      def ret_attribute_idhs(assembly_idh)
        ret = ret_matching_attribute_idhs([assembly_idh],pattern)
        #if does not exist then create the attribute
        if ret.empty?
          af = ret_filter(pattern,:attribute)
          #attribute must have simple form 
          unless af.kind_of?(Array) and af.size == 3 and af[0..1] == [:eq,:display_name]
            raise Error.new("cannot create new attribute from attribute pattern #{pattern}")
          end
          field_def = {"display_name" => af[2]}
          ret = assembly_idh.create_object().create_or_modify_field_def(field_def)
        end
        ret
      end
    end

    class ComponentLevel < self
      def ret_attribute_idhs(assembly_idh)
        ret = Array.new
        node_idhs = ret_matching_node_idhs(assembly_idh)
        return ret if node_idhs.empty?

        pattern  =~ /^node[^\/]*\/(component.+$)/
        cmp_fragment = $1
        cmp_idhs = ret_matching_component_idhs(node_idhs,cmp_fragment)
        return ret if cmp_idhs.empty?

        cmp_fragment =~ /^component[^\/]*\/(attribute.+$)/  
        attr_fragment = $1
        ret_matching_attribute_idhs(cmp_idhs,attr_fragment)
      end
    end

   private 
    def initialize(pattern)
      @pattern = pattern
    end
    attr_reader :pattern

    #TODO: more efficient to use joins of below
    def ret_matching_node_idhs(assembly_idh)
      filter = [:eq, :assembly_id, assembly_idh.get_id()]
      if node_filter = ret_filter(pattern,:node)
        filter = [:and, filter, node_filter]
      end
      sp_hash = {
        :cols => [:display_name,:id],
        :filter => filter
      }
      Model.get_objs(assembly_idh.createMH(:node),sp_hash).map{|r|r.id_handle()}
    end

    def ret_matching_component_idhs(node_idhs,cmp_fragment)
      filter = [:oneof, :node_node_id, node_idhs.map{|idh|idh.get_id()}]
      if cmp_filter = ret_filter(cmp_fragment,:component)
        filter = [:and, filter, cmp_filter]
      end
      sp_hash = {
        :cols => [:display_name,:id],
        :filter => filter
      }
      sample_idh = node_idhs.first
      Model.get_objs(sample_idh.createMH(:component),sp_hash).map{|r|r.id_handle()}
    end

    def ret_matching_attribute_idhs(cmp_idhs,attr_fragment)
      filter = [:oneof, :component_component_id, cmp_idhs.map{|idh|idh.get_id()}]
      if attr_filter = ret_filter(attr_fragment,:attribute)
        filter = [:and, filter, attr_filter]
      end
      sp_hash = {
        :cols => [:display_name,:id],
        :filter => filter
      }
      sample_idh = cmp_idhs.first
      Model.get_objs(sample_idh.createMH(:attribute),sp_hash).map{|r|r.id_handle()}
    end

    def ret_filter(fragment,type)
      if fragment =~ /[a-z]\[([^\]]+)\]/
        filter = $1
        if filter == "*"
          nil
        elsif filter =~ /^[a-z0-9_-]+$/
          case type
           when :attribute
            [:eq,:display_name,filter]
           when :component
            [:eq,:component_type,filter]
           when :node
            [:eq,:display_name,filter]
           else
            raise ErrorNotImplementedYet.new()
          end
        else
          raise ErrorNotImplementedYet.new()
        end
      else
        nil #without qualification means all (no filter)
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

