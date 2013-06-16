require  require File.expand_path("common", File.dirname(__FILE__))
require 'pp'
Sequel.migration do
  up do 
    cmp_module_refs = DB[:module__component_module_refs].select(:id,:content,:branch_id).all()
    info_table = DB[:top__id_info].filter(:relation_id=>cmp_module_refs.map{|r|r[:id]}).all()
pp info_table
    raise "forced error"
  end
end
