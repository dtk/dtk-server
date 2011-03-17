#!/bin/sh
dropdb -U postgres db_main ; createdb -U postgres db_main 
cd /root/R8Server/application/
./spec/dbrebuild.rb 
./spec/import_test.rb spec/data_source_entries/chef_library.json /library/test
./spec/import_test.rb spec/data_source_entries/ec2_library.json /library/test 
./spec/import_test.rb spec/data_source_entries/user_data_library.json /library/test
./spec/import_test.rb spec/data_source_entries/basic_datacenter.json  



