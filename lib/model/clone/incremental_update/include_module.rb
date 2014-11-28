module DTK; class Clone
  class IncrementalUpdate
    class IncludeModule < self
      def initialize(cmp_template_links)
        super(cmp_template_links)
      end
      # TODO: put in equality test so that does not need to do the modify equal objects
      def self.equal_so_no_modify?(instance,template)
        false
      end
     private
      def get_ndx_objects(component_idhs)
        ret = Hash.new
        ::DTK::Component.get_include_modules(component_idhs,:cols_plus => [:component_id,:ancestor_id]).each do |r|
          (ret[r[:component_id]] ||= Array.new) << r
        end
        ret
      end
    end
  end
end; end
