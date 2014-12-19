module DTK; class Clone
  class IncrementalUpdate
    class IncludeModule < self
     private
      # TODO: put in equality test so that does not need to do the modify equal objects
      def equal_so_dont_modify?(instance,template)
        false
      end

      def get_ndx_objects(component_idhs)
        ret = Hash.new
        ::DTK::Component.get_include_modules(component_idhs,:cols_plus => [:component_id,:ref]).each do |r|
          (ret[r[:component_id]] ||= Array.new) << r
        end
        ret
      end
    end
  end
end; end
