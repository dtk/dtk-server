module DTK; class Clone
  class IncrementalUpdate
    class ComputeIncludeModule < self
      def initialize(cmp_template_links)
        super(cmp_template_links)
      end
      # TODO: put in equality test so that does not need to do the modify of equal objects
      def self.equal?(instance,template)
        false
      end
     private
      def get_ndx_objects(component_idhs)
         # TODO: need to write; stub
        component_idhs.inject(Hash.new){|h,idh|h.merge(idh.get_id() => Array.new)}
      end
    end
  end
end; end
