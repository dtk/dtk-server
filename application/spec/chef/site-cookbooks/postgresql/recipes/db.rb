Chef::Log.info("in postgresql::db")
require 'pp'
node[:postgresql][:db][:list].each do |el|
  Chef::Log.info("in postgresql::db #{el.to_hash.inspect}")
end
=begin
process_db_instances "instances" do
  elements node[:postgresql][:db][:list]
end
=end

