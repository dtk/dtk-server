module DTK
  class Module
    # must be before components and service
#    r8_nested_require('module','dsl_parser')
  end

  # TODO eventually move to useing Module:: variants
  # order is important
  r8_nested_require('module','mixins')
  r8_nested_require('module','module_ref')
  r8_nested_require('module','module_refs')
  r8_nested_require('module','component')
  r8_nested_require('module','service')
  r8_nested_require('module','test')
  r8_nested_require('module','node')
  r8_nested_require('module','branch')
  r8_nested_require('module','version')
  r8_nested_require('module','assembly_module')
end
