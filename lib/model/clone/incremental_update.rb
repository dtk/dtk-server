module DTK; class Clone
  # These mdouels explicitly have class to the sub object type in contrast to 
  # initial clone, which does not              
  module IncrementalUpdate
    r8_nested_require('incremental_update','component')
    r8_nested_require('incremental_update','dependency')

    class InstanceTemplateLink < Array
      def add(instance,template,instance_parent=nil)
        el = {:instance => instance, :template => template}
        el.merge!(:instance_parent => instance_parent) if instance_parent
        self << el
      end

      def template(instance)
        match = match_instance(instance)
        match[:template] || raise(Error.new("Cannot find matching template for instance (#{instance.inspect})"))
      end

      def match_instance(instance)
        instance_id = instance.id
        unless match = find{|r|r[:instance] and r[:instance].id == instance_id}
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
        inject(Hash.new) do |h,el|
          template = el[:template]
          h.merge(template ? {template.id => template} : {})
        end.values
      end
     
      def instances()
        #no dups
        map{|el|el[:instance]}.compact
      end
    end
  end
end; end
