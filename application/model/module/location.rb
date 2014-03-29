#
# Classes that encapsulate information for each module or moulde branch where is its location clone and where is its remotes
#
module DTK
  class ModuleLocation
    #target classes correspond to where remotes and local clones are
    r8_nested_require('location','target')
    r8_nested_require('location','branch')
  end
end
