#!/usr/bin/env ruby
root = File.expand_path('../', File.dirname(__FILE__))

puts
puts "Script that changes references from 'memory_size' to 'instance_size'"
puts

require root + '/app'
include DTK
default_project = Project.get_all(ModelHandle.new(c = 2, :project)).first
Model.get_objs(default_project.model_handle(:user), { cols: User.common_columns })

session = CurrentSession.new
session.set_user_object(default_project.get_field?(:user))
session.set_auth_filters(:c, :group_ids)
sp_hash = {
 cols: [:id, :display_name],
 filter: [:eq, :display_name, 'memory_size']
}
attr_mh = default_project.model_handle(:attribute)
memory_size_attrs = Model.get_objs(attr_mh, sp_hash)
number_of_changes = memory_size_attrs.size
if number_of_changes == 0
  puts "No instances of 'memory_size' found"
else
  update_rows = memory_size_attrs.map { |r| r.merge(display_name: 'instance_size') }
  Model.update_from_rows(attr_mh, update_rows)
  puts "#{number_of_changes.to_s} instances of 'memory_size' have been converted to 'instance_size'"
end
