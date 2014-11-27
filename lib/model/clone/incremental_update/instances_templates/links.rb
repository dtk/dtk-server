module DTK; class Clone; class IncrementalUpdate
  module InstancesTemplates
    class Links < Array
      def add?(instances,templates,parent_link)
        # do not add if both instances and templates are empty?
        unless instances.empty? and templates.empty?
          self << Link.new(instances,templates,parent_link)
        end
      end

      def update_model(object_klass)
        opts = object_klass.update_opts()
        delete_instances = Array.new 
        create_from_templates = Array.new
        modify_instances = Clone::InstanceTemplate::Links.new
        each do |link|
          # indexd by ref
          ndx_templates = link.templates.inject(Hash.new) do |h,t|
            h.merge(t[:ref] => {:template => t,:matched => false})
          end
          link.instances.each do |instance|
            if template_match = ndx_templates[instance[:ref]]
              template = template_match[:template]
              unless object_klass.equal?(instance,template)
                modify_instances.add(instance,template_match[:template])
                template_match[:matched] = true
              end
            else
              delete_instances << instance
            end
          end
          ndx_templates.values.each do |r|
            unless r[:matched]
              create_from_templates << {:template => r[:template], :parent_link => link.parent_link}
            end
          end
        end
        delete_instances(delete_instances,opts) unless delete_instances.empty? 
        modify_instances(modify_instances) unless modify_instances.empty?
        create_from_templates(create_from_templates) unless create_from_templates.empty?
      end

     private
      def delete_instances(instances,opts={})
        if opts[:donot_allow_deletes]
          mn = delete_instances.first.model_name
          instance_names = delete_instances.map{|r|r[:display_name]}.join(',')
          raise ErrorUsage.new("The change to the dtk.model.yaml for would case the #{mn} objects (#{instance_names}) to be deleted")
        else
          Model.delete_instances(instances.map{|r|r.id_handle})
        end
      end
      
      def modify_instances(instance_template_links)
        Clone.modify_instances(instance_template_links)
      end
      def create_from_templates(template__parent_links)
        # TODO: more efficient is group by common parent_links and pass all templates that are relevant at one time
        template__parent_links.each do |r|
          Clone.create_child_object([r[:template].id_handle],r[:parent_link])
        end
      end

    end
  end
end; end; end
