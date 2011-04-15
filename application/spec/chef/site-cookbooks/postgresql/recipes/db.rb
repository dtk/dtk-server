Chef::Log.info("in postgresql::db")
require 'pp'
pp node[:postgresql][:db][:list].to_hash
=begin
process_db_instances "instances" do
  elements node[:postgresql][:db][:list]
end
=end

