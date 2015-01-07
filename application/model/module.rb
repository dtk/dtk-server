# TODO: need to cleanup breaking into  base_module, component_module, service_module and the DSL related classes
# There is overlap between soem service module and otehr moduel code
# Right now seems intuitive model is that we have
# two types of modules: service module and the rest, the prime being the component module, and that for the rest there is much similarity
# for the rest the classes used are 
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
