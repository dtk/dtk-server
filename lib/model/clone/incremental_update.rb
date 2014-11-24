module DTK; class Clone
  # These mdouels explicitly have class to the sub object type in contrast to 
  # initial clone, which does not              
  module IncrementalUpdate
    # Helper classes
    r8_nested_require('incremental_update','instance_template_links')
    r8_nested_require('incremental_update','instances_templates_links')
    # classes for processing specific object model types
    r8_nested_require('incremental_update','component')
    r8_nested_require('incremental_update','dependency')
  end
end; end
