# TODO: need to cleanup breaking into module, base_module and component_module
module DTK
  # order is important
  r8_nested_require('module','mixins')
  r8_nested_require('module','module_ref')
  r8_nested_require('module','module_refs')
  r8_nested_require('module','dsl_parser')
  r8_nested_require('module','base_module')
  r8_nested_require('module','component_module')
  r8_nested_require('module','service')
  r8_nested_require('module','test')
  r8_nested_require('module','node')
  r8_nested_require('module','branch')
  r8_nested_require('module','version')
  r8_nested_require('module','assembly_module')
end
