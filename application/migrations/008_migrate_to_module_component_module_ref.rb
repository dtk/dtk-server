require File.expand_path("common", File.dirname(__FILE__))
require 'pp'
Sequel.migration do
  up do 
   #TODO: this is just testing a number of things now
    m = DTKMigration.new
    m.db_rebuild(:component_module_ref,:module_branch)
    cmp_mod_refs = m.get_objs(:component_module_refs,:cols => [:id,:ref,:content,:branch_id])
    pp cmp_mod_refs
    new_rows = Array.new
    cmp_mod_refs.each do |r|
      content = r[:content]
      unless content.nil? or content.empty?
        unless content.keys == [:component_modules]
          raise "content not treated: #{content.inspect}"
        end

        content[:component_modules].each do |cmp_mod_sym,ver|
          cmp_mod = cmp_mod_sym.to_s
          new_row = {
            :old_id => r[:id],
            :ref => cmp_mod,
            :branch_id => r[:branch_id],
            :version_info => ver,
            :component_module => cmp_mod
            }
          new_rows << new_row
        end
      end
    end
    m.create_objs(:component_module_ref,:module_branch,new_rows,:component_module_refs)
    pp m.get_objs(:component_module_ref,:cols => [:id,:ref,:component_module,:version_info,:branch_id])

#    pp  DB[:module__component_module_ref].all()
   # pp [:test_new_table_there,DB[:module__component_module_ref].select(:id,:version_info,:branch_id,:component_component_id).all()]
   # cmp_module_refs = DB[:module__component_module_refs].select(:id,:content,:branch_id).all()
   # info_table = DB[:top__id_info].filter(:relation_id=>cmp_module_refs.map{|r|r[:id]}).all()
#pp info_table
    raise "forced error"
  end
end
