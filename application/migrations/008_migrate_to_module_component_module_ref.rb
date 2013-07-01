require File.expand_path("common", File.dirname(__FILE__))
require 'pp'
Sequel.migration do
  up do 
   #TODO: this is just testing a number of things now
    DTKMigration.dtk_model_context do
      dtk_db_rebuild(:component_module_ref,:module_branch)

      #use :component_module_refs to build :component_module_ref
      cmp_mod_refs = dtk_select(:component_module_refs,:cols => [:id,:ref,:content,:branch_id])
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
      dtk_create(:component_module_ref,:module_branch,new_rows,:component_module_refs)

      #will have to clean this up later
      rename_table :module__component_module_refs,"module__old---component_module_refs".to_sym
#      cmr = dtk_select(:component_module_ref,:cols => [:id,:owner_id,:group_id,:ref,:ref_num,:created_at,:component_module,:version_info,:branch_id])
 #     pp cmr
  #    pp  DB[:top__id_info].filter(:relation_id => cmr.map{|r|r[:id]}).all()
   #   pp DB["module__old---component_module_refs".to_sym].all
     end
  end
end
