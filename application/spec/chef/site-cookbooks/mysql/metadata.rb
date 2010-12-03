description       "Installs and configures mysql for client or server"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))

version           "0.24.0"
recipe            "mysql::client", "Installs packages required for mysql clients using run_action magic"
recipe            "mysql::server", "Installs packages required for mysql servers w/o manual intervention"
recipe            "mysql::server2", "Installs packages required for mysql servers w/o manual intervention"
recipe            "mysql::server_ec2", "Performs EC2-specific mountpoint manipulation"
recipe            "mysql::client_app1", "Sample client application that connects to a mysql database"
recipe            "mysql::slave", "For extending mysql server to serve as a slave"
recipe            "mysql::master", "For extending mysql server to serve as a master"

%w{ debian ubuntu }.each do |os|
  supports os
end

depends "openssl"

attribute "mysql/server_root_password",
  :display_name => "MySQL Server Root Password",
  :description => "Randomly generated password for the mysqld root user",
  :recipes => ["mysql::server","mysql::server2"]

attribute "mysql/bind_address",
  :display_name => "MySQL Bind Address",
  :description => "Address that mysqld should listen on",
  :recipes => ["mysql::server","mysql::server2"]

attribute "mysql/datadir",
  :display_name => "MySQL Data Directory",
  :description => "Location of mysql databases",
  :default => "/var/lib/mysql",
  :recipes => ["mysql::server","mysql::server2"]

attribute "mysql/ec2_path",
  :display_name => "MySQL EC2 Path",
  :description => "Location of mysql directory on EC2 instance EBS volumes",
  :default => "/mnt/mysql",
  :recipes => ["mysql::server","mysql::server2"]

attribute "mysql/tunable",
  :display_name => "MySQL Tunables",
  :description => "Hash of MySQL tunable attributes",
  :type => "hash",
  :recipes => ["mysql::server","mysql::server2"]

attribute "mysql/tunable/key_buffer",
  :display_name => "MySQL Tuntable Key Buffer",
  :default => "250M",
  :recipes => ["mysql::server","mysql::server2"]

attribute "mysql/tunable/max_connections",
  :display_name => "MySQL Tunable Max Connections",
  :default => "800",
  :recipes => ["mysql::server","mysql::server2"]

attribute "mysql/tunable/wait_timeout",
  :display_name => "MySQL Tunable Wait Timeout",
  :default => "180",
  :recipes => ["mysql::server","mysql::server2"]

attribute "mysql/tunable/net_read_timeout",
  :display_name => "MySQL Tunable Net Read Timeout",
  :default => "30",
  :recipes => ["mysql::server","mysql::server2"]

attribute "mysql/tunable/net_write_timeout",
  :display_name => "MySQL Tunable Net Write Timeout",
  :default => "30",
  :recipes => ["mysql::server","mysql::server2"]

attribute "mysql/tunable/back_log",
  :display_name => "MySQL Tunable Back Log",
  :default => "128",
  :recipes => ["mysql::server","mysql::server2"]

attribute "mysql/tunable/table_cache",
  :display_name => "MySQL Tunable Table Cache",
  :default => "128",
  :recipes => ["mysql::server","mysql::server2"]

attribute "mysql/tunable/max_heap_table_size",
  :display_name => "MySQL Tunable Max Heap Table Size",
  :default => "32M",
  :recipes => ["mysql::server","mysql::server2"]


###TODO may put in seperate file
attribute "_meta_info",
  :basic_types => {
    "mysql::server" => "service", 
    "mysql::server2" => "service", 
    "mysql::client" => "package",
    "mysql::slave" => {"feature" => {"base_recipes" => ["mysql::server" ,"mysql::server2"]}},
    "mysql::master" => {"feature" => {"base_recipes" => ["mysql::server" ,"mysql::server2"]}},
   }



require File.expand_path('metadata_aux.rb',::Chef::Config[:cucumber_path]);__t(__FILE__,self)
