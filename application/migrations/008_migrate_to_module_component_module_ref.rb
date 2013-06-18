require File.expand_path("common", File.dirname(__FILE__))
require 'pp'
Sequel.migration do
  up do 
   #TODO: this is just testing a number of things now
    m = DTKMigration.new
    m.db_rebuild(:component_module_ref,:module_branch)
    cmp_mod_refs = m.get_objs(:component_module_refs,:cols => [:id,:content])
    pp cmp_mod_refs
    new_rows = cmp_mod_refs.map{|r|{:old_id => r[:id],:version_info => r[:content]}}
    m.create_objs(:component_module_ref,new_rows,:component_module_refs)
   # pp [:test_new_table_there,DB[:module__component_module_ref].select(:id,:version_info,:branch_id,:component_component_id).all()]
   # cmp_module_refs = DB[:module__component_module_refs].select(:id,:content,:branch_id).all()
   # info_table = DB[:top__id_info].filter(:relation_id=>cmp_module_refs.map{|r|r[:id]}).all()
#pp info_table
    raise "forced error"
  end
end
