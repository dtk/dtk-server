module DTK; class Clone
  module IncrementalUpdate
    class InstancesTemplatesLinks < Array
      r8_nested_require('instances_templates_links','link')
      def add?(instances,templates,parent_link)
        # do not add if both instances and templates are empty?
        unless instances.empty? and templates.empty?
          self << Link.new(instances,templates,parent_link)
        end
      end
      def update_model(opts={})
        delete_instances = Array.new 
        create_from_templates = Array.new
        modify_instances = InstanceTemplateLinks.new
        each do |link|
          # indexd by ref
          ndx_templates = link.templates.inject(Hash.new) do |h,t|
            h.merge(t[:ref] => {:template => t,:matched => false})
          end
          link.instances.each do |instance|
            if template_match = ndx_templates[instance[:ref]]
              modify_instances.add(instance,template_match[:template])
              template_match[:matched] = true
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
        pp(
           :delete_instances => delete_instances,
           :modify_instances =>  modify_instances,
           :create_from_templates => create_from_templates
           )
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
      end

      def create_from_templates(create_info)
      end

      def field_set_to_copy()
        return @field_set_to_copy if @field_set_to_copy
        instance_mh = instance_mh()
        parent_id_col = instance_mh.parent_id_field_name()
        remove_cols = [:id,:local_id,parent_id_col]
        concrete_model_name = Model.concrete_model_name(instance_mh[:model_name])
        @field_set_to_copy = Model::FieldSet.all_real(concrete_model_name).with_removed_cols(*remove_cols)
      end

      def instance_mh()
        return @instance_mh if @instance_mh 
        unless link = first 
          raise Error.new("This methdo should not be called when no links")
        end
        @instance_mh = link.instance_model_handle()
      end

    end
  end
end; end
