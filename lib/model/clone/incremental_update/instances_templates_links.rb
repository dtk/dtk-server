module DTK; class Clone
  module IncrementalUpdate
    class InstancesTemplatesLinks < Array
      def add?(instances,templates,instance_parent)
        # do not add if both instances and templates are empty?
        unless instances.empty? and templates.empty?
          self << Link.new(instances,templates,instance_parent)
        end
      end
      def update_model(opts={})
        delete_instances = Array.new 
        add_templates = Array.new
        modify_instances = InstanceTemplateLinks.new
        each do |link|
          # ndexd by ref
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
              add_templates << {:template => r[:template], :instance_parent => link.instance_parent}
            end
          end
        end
        pp(
           :delete_instances => delete_instances,
           :modify_instances =>  modify_instances,
           :add_templates => add_templates
           )
        delete_instances(delete_instances,opts) unless delete_instances.empty? 
        modify_instances(modify_instances) unless modify_instances.empty?
        add_templates(add_templates) unless add_templates.empty?
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

      def add_templates(template_parent_instance_pairs)
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

      class Link
        attr_reader :instances,:templates,:instance_parent
        def initialize(instances,templates,instance_parent)
          @instances = instances
          @templates = templates
          @instance_parent = instance_parent
        end

        def instance_model_handle()
          #want parent information
          @instance_parent.child_model_handle(instance_model_name())
        end
        private
        def instance_model_name()
          #all templates and instances should have same model name so just need to find one
          #one of these wil be non null
        (@instances.first || @templates.first).model_name
        end
      end
    end
  end
end; end
