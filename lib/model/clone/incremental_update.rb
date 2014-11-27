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
      links.update_model(self.class) unless links.empty?
    end
    # can be overwritten; used for detecting with an isnatnce and template are euqal and thus modification not needed
    def self.equal_so_no_modify?(instance,template)
      false
    end

    # can be overwritten; this is options when updating (i.e., delete, modify, create) objects
    def self.update_opts()
      Hash.new
    end

   private
    # must be overwritten; this method returns a hash where key is parent id and value is array of objects under this
    # parent; the objects are both instances and templates
    def get_ndx_objects(parent_idhs)
      raise Error.new("Abstract method that should be overwritten")
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
  end
end; end
