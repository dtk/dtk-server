module DTK; class Clone
  class IncrementalUpdate
    class Dependency < self
      def initialize(cmp_template_links)
        super(cmp_template_links)
      end
      # TODO: put in equality test so that does not need to do the modify equal objects
      def self.equal?(instance,template)
        false
      end
     private
      def get_ndx_objects(component_idhs)
        ::DTK::Component::Dependency.get_nested_dependencies(component_idhs).inject(Hash.new) do |h,r|
          h.merge(r[:id] => r[:dependencies])
        end
      end
    end
  end
end; end
