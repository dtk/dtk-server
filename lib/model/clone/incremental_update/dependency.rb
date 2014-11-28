module DTK; class Clone
  class IncrementalUpdate
    class Dependency < self
     private
      # TODO: put in equality test so that does not need to do the modify equal objects
      def self.equal_so_no_modify?(instance,template)
        false
      end

      def get_ndx_objects(component_idhs)
        ::DTK::Component::Dependency.get_nested_dependencies(component_idhs).inject(Hash.new) do |h,r|
          h.merge(r[:id] => r[:dependencies])
        end
      end
    end
  end
end; end
