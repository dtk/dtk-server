require File.expand_path("common", File.dirname(__FILE__))
require 'pp'
Sequel.migration do
  up do 
   #TODO: this is just testing a number of things now
    DTKMigration.dtk_model_context do
      dtk_db_rebuild(:component_module_ref,:module_branch)
      cmp_mod_refs = dtk_get_objs(:component_module_refs,:cols => [:id,:ref,:content,:branch_id])
#      pp cmp_mod_refs
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
      dtk_create_objs(:component_module_ref,:module_branch,new_rows,:component_module_refs)
      cmr = dtk_get_objs(:component_module_ref,:cols => [:id,:owner_id,:group_id,:ref,:ref_num,:created_at,:component_module,:version_info,:branch_id])

      pp cmr
      pp  DB[:top__id_info].filter(:relation_id => cmr.map{|r|r[:id]}).all()
      raise "still need to have top.id_info get parent info"
=begin
Example of id.info_top table w/o parent info
{:ref=>"thin",
  :relation_type=>"component_module_ref",
  :relation_local_id=>98632,
  :ref_num=>nil,
  :parent_id=>0,
  :uri=>"/component_module_ref/thin",
  :is_factory=>false,
  :relation_name=>"module.component_module_ref",
  :c=>2,
  :parent_relation_type=>nil,
  :relation_id=>2147582280}
=end
    end
  end
end
