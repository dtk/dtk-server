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

    # can be overwritten; used for detecting with an isnatnce and template are euqal and thus modification not needed
    def self.equal?(instance,template)
      false
    end
  end
end; end
