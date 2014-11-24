module DTK; class Clone
  # These mdouels explicitly have class to the sub object type in contrast to 
  # initial clone, which does not              
  module IncrementalUpdate
    r8_nested_require('incremental_update','component')
    r8_nested_require('incremental_update','dependency')

    class InstanceTemplateLink < Array
      def add(instance,template)
        self << {:instance => instance, :template => template}
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

    class InstancesTemplatesLink < Array
      def add(instances,templates,instance_parent)
        self << {:instances => instances, :templates => templates,:instance_parent => instance_parent}
      end
      def update_model()
        delete_instances = Array.new 
        templates_to_clone = Array.new
        modify_instances = InstanceTemplateLink.new
        each do |link|
          ndx_templates = link[:templates].inject(Hash.new) do |h,t|
            h.merge(t[:id] => {:template => t,:matched => false})
          end
          link[:instances].each do |instance|
            if template_match = ndx_templates[instance[:ancestor_id]]
              modify_instances.add(instance,template_match[:template])
              template_match[:matched] = true
            else
              delete_instances << instance
            end
          end
          ndx_templates.values.each do |r|
            unless r[:matched]
              templates_to_clone << {:template => r[:template], :instance_parent => link[:instance_parent]}
            end
          end
        end
        pp(
           :delete_instances => delete_instances,
           :modify_instances =>  modify_instances,
           :templates_to_clone => templates_to_clone
           )
      end
    end
  end
end; end
