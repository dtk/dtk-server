module DTK; class Clone
  # The incremental update code explicitly has classes per sub object type in contrast to 
  # initial clone, which aside from spacial processing has generic mecahnism for parent child processing
 class IncrementalUpdate
    # helper fns
    module InstancesTemplates
      r8_nested_require('incremental_update','instances_templates/link')
      r8_nested_require('incremental_update','instances_templates/links')
    end
    # classes for processing specific object model types
    r8_nested_require('incremental_update','component')
    r8_nested_require('incremental_update','dependency')
    r8_nested_require('incremental_update','include_module')
    r8_nested_require('incremental_update','attribute')

    # parent_links is of type Clone::InstanceTemplate::Links
    def initialize(parent_links=nil)
      @parent_links = parent_links
    end
    def update?()
      links = get_instances_templates_links()
      update_model?(links)
    end

   private
    # must be overwritten; this method returns a hash where key is parent id and value is array of objects under this
    # parent; the objects are both instances and templates
    def get_ndx_objects(parent_idhs)
      raise Error.new("Abstract method that should be overwritten")
    end

    # can be overwritten; fori fields that dont want template to ovewrite isnatnce, copy from instance field
    # to target fields to compensate
    def sync_no_copy_fields!(instance,template)
      nil
    end

    # can be overwritten; used for detecting with an isnatnce and template are euqal and thus modification not needed
    def equal_so_dont_modify?(instance,template)
      false
    end

    # can be overwritten; this is options when updating (i.e., delete, modify, create) objects
    def update_opts()
      Hash.new
    end

    def get_instances_templates_links()
      ret = InstancesTemplates::Links.new()
      parent_idhs = @parent_links.all_id_handles()
      ndx_objects = get_ndx_objects(parent_idhs)
      @parent_links.each do |parent_link|
        parent_instance = parent_link.instance
        instances = (parent_instance && ndx_objects[parent_instance.id])||[]
        parent_template = parent_link.template
        templates = (parent_template && ndx_objects[parent_template.id])||[]
        ret.add?(instances,templates,parent_link)
      end
      ret
    end

    def update_model?(links)
      return if links.empty?
      opts = update_opts()
      delete_instances = Array.new 
      create_from_templates = Array.new
      modify_instances = Clone::InstanceTemplate::Links.new()
      links.each do |link|
        # TODO: make sure all objects can use ref as key; if not make this a function of the class
        # indexed by ref
        ndx_templates = link.templates.inject(Hash.new) do |h,t|
          unless key = t[:ref]
            Log.error("Unexpected that object (#{t.inspect}) does not have field :ref")
            next
          end
          h.merge(key => {:template => t,:matched => false})
        end
        link.instances.each do |instance|
          unless key = instance[:ref]
            Log.error("Unexpected that object (#{instance.inspect}) does not have field :ref")
            next
          end
          if template_match = ndx_templates[key]
            template = template_match[:template]
            unless equal_so_dont_modify?(instance,template)
              sync_no_copy_fields!(instance,template)
              modify_instances.add(instance,template)
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
      modify_instances(links.instance_model_handle(),modify_instances) unless modify_instances.empty?
      create_from_templates(create_from_templates) unless create_from_templates.empty?
    end

    def delete_instances(instances,opts={})
      if opts[:donot_allow_deletes]
        mn = instances.first.model_name
        instance_names = instances.map{|r|r[:display_name]}.join(',')
        raise ErrorUsage.new("The change to the dtk.model.yaml for would case the #{mn} objects (#{instance_names}) to be deleted")
      else
        Model.delete_instances(instances.map{|r|r.id_handle})
      end
    end
      
    def modify_instances(instance_model_handle,instance_template_links)
      Clone.modify_instances(instance_model_handle,instance_template_links)
    end

    def create_from_templates(template__parent_links)
      # TODO: more efficient is group by common parent_links and pass all templates that are relevant at one time
      template__parent_links.each do |r|
        Clone.create_child_object([r[:template].id_handle],r[:parent_link])
      end
    end
  end
end; end
