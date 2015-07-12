#!/usr/bin/env ruby
root = File.expand_path('../', File.dirname(__FILE__))

puts
puts "\tWARNING!\tWARNING!\tWARNING!\tWARNING!"
puts
puts 'Make sure that your run this script ONLY ONCE, multiple runs will cause data corruption. press ENTER key to continue OR CTRL^C to stop'
a = $stdin.gets
puts 'Hashing catalog passwords ...'

require root + '/app'

default_project = ::DTK::Project.get_all(::DTK::ModelHandle.new(c = 2, :project)).first
::DTK::Model.get_objs(default_project.model_handle(:user), { cols: ::DTK::User.common_columns })

session = ::DTK::CurrentSession.new
session.set_user_object(default_project.get_field?(:user))
session.set_auth_filters(:c, :group_ids)

users = ::DTK::Model.get_objs(default_project.model_handle(:user), { cols: [:id, :password, :catalog_password] })

users.each do |user|
  if user[:catalog_password]
    user.update(catalog_password: ::DTK::DataEncryption.hash_it(user[:catalog_password]))
  end
end

::DTK::Model.update_from_rows(default_project.model_handle(:user), users)

puts 'Catalog passwords have been hashed successfully!'
