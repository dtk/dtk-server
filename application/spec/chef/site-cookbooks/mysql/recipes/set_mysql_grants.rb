# TBD: only for debian now
db_info = Hash.new
if node[:mysql][:databases]
  node[:mysql][:databases].each do |db| 
   db_info["top"] = db
  end
end

template "/etc/mysql/grants.sql" do
  source "grants.sql.erb"
  owner "root"
  group "root"
  mode "0600"
  action :create
  variables(
    :db_info => db_info,
    :root_pw => node[:mysql][:server_root_password]
  )
end


