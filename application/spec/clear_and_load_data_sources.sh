#!/bin/sh
cd /root/R8Server/application/
./spec/clear_db.sh
./spec/dbrebuild.rb 
./spec/import_test.rb spec/data_source_entries/chef_library.json /library/test
./spec/import_test.rb spec/data_source_entries/ec2_library.json /library/test 
./spec/import_test.rb spec/data_source_entries/user_data_library.json /library/test
./spec/import_test.rb spec/data_source_entries/basic_datacenter.json /datacenter/dc1 


