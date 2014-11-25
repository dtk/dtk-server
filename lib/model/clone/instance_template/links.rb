module DTK; class Clone
  module InstanceTemplate
    class Links < Array
      def add(instance,template)
        self << Link.new(instance,template)
      end

      def parent_rels()
        map{|link|{:ancestor_id => link.instance.id, :old_par_id => link.template.id}}
      end

      def template(instance)
        match = match_instance(instance)
        match[:template] || raise(Error.new("Cannot find matching template for instance (#{instance.inspect})"))
      end

      def match_instance(instance)
        instance_id = instance.id
        unless match = find{|l|l.instance and l.instance.id == instance_id}
          raise(Error.new("Cannot find match for instance (#{instance.inspect})"))
        end
        match
      end

      def all_id_handles()
        templates().map{|r|r.id_handle()} + instances().map{|r|r.id_handle()}
      end
      
     private
      def templates()
        #removes dups
        inject(Hash.new) do |h,l|
          template = l.template
          h.merge(template ? {template.id => template} : {})
        end.values
      end
     
      def instances()
        #does not have dups
        map{|l|l.instance}.compact
      end
    end
  end
end; end