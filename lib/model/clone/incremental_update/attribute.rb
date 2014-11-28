module DTK; class Clone
  class IncrementalUpdate
    class Attribute < self
     private
      # TODO: put in equality test so that does not need to do the modify equal objects
      def equal_so_dont_modify?(instance,template)
        false
      end
      
      def update_opts()
        # TODO: can refine to allow deletes if instance has nil value and not in any attribute link
        # can do this by passing in a charachterstic fn
        {:donot_allow_deletes => true}
      end
      
      def get_ndx_objects(component_idhs)
        ret = Hash.new
        ::DTK::Component.get_attributes(component_idhs,:cols_plus => [:component_component_id,:ancestor_id]).each do |r|
          (ret[r[:component_component_id]] ||= Array.new) << r
        end
        ret
      end

    end
  end
end; end
