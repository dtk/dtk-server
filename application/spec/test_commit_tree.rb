#!/usr/bin/env ruby
root = File.expand_path('../', File.dirname(__FILE__))
require root + '/app'
datacenter_id = ARGV[0]
include XYZ
w = WorkspaceController.new
w.commit(datacenter_id)
=begin
pending_changes = Ramaze::Helper::GetPendingChanges::flat_list_pending_changes_in_datacenter(datacenter_id.to_i)
unless pending_changes.empty?
  commit_task = create_task_from_pending_changes(pending_changes)
  commit_task.save!()
  commit_tree = commit_task.render_form()
  add_i18n_strings_to_rendered_tasks!(commit_tree)
  pp [:commit_tree,commit_tree]
  delete_instance(commit_task.id())
end
=end


