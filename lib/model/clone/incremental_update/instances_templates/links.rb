module DTK; class Clone; class IncrementalUpdate
  module InstancesTemplates
    class Links < Array
      def add?(instances,templates,parent_link)
        # do not add if both instances and templates are empty?
        unless instances.empty? and templates.empty?
          self << Link.new(instances,templates,parent_link)
        end
      end

      def update_model(object_klass,opts={})
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
        cols_to_copy = field_set_to_copy().cols 
        templates_to_copy = instance_template_links.get_templates_with_cols(cols_to_copy + [:id])
        ndx_templates_to_copy = templates_to_copy.inject(Hash.new){|h,r|h.merge(r.id => r)}
        instances_to_update = instance_template_links.map do |l|
          template_id = l.template.id
          instance_id = l.instance.id
          ndx_templates_to_copy[template_id].merge(:id => instance_id)
        end
        pp [:instances_to_update,instances_to_update]
        Model.update_from_rows(instance_mh(),cols_to_copy,:convert => true)
      end
      # TODO: might unify how update and create are done; modify_instances bring all rows into memory and is
      # is simpler to understand while create_from_templates uses Clone metheds that use create from select
      def create_from_templates(template__parent_links)
        # TODO: more efficient is group by common parent_links and pass all templates that are relevant at one time
        template__parent_links.each do |r|
          Clone.create_child_object([r[:template].id_handle],r[:parent_link])
        end
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
          raise Error.new("This method should not be called when no links")
        end
        @instance_mh = link.instance_model_handle()
      end

    end
  end
end; end; end
