require "../../require_first.rb" #TODO: just for testing
#
# Classes that encapsulate information for each module or moulde branch where is its location clone and where is its remotes
#
module DTK
  class ModuleLocation
    #thsse classes correspond to where remotes and local clones are
    r8_nested_require('location','local')
    r8_nested_require('location','remote')
    #above needed before below
    r8_nested_require('location','server')
    r8_nested_require('location','client')

#    r8_nested_require('location','branch')
  end
end

#TODO: just for testing
require 'pp'
pp DTK::ModuleLocation::Server::Local.new({})
