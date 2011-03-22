
{
  :display_name => 'Name',
  :parent_name => 'Parent',
  :attribute_value => 'Value',
  :external_ref => 'External Attr Reference',
  :value_asserted => 'Value Asserted',
  :required => 'Required',
  :data_type => 'Data Type',
  :semantic_type => 'Semantic Type',
  :is_port => 'Is Port',
  :description => 'Description',
  :needs_to_be_set => "Needs to be set",
  :is_unset => "Is Unset",
  :external_ref => 'Ext Attr Ref',
  :required_list => 'Req',
  :description_list => 'Descr',

#generic SAP related
  :sap__l4 => 'IPv4 Output',
  :sap_config__l4 => 'SAP Config IPV4',
  :sap__socket => 'SAP Socket',
  :sap_ref__l4 => 'Input Conn',
  :sap_config__l4__port => "Port",
  :sap_config__l4__protocol => "Protocol",
  :sap_ref__l4__port => "Port",
  :sap_ref__l4__protocol => "Protocol",
  :sap_ref__l4__host_address => "Host Addr",
  :sap_config__db__name => "DB Name",
  :sap_config__db__owner => "DB User",
  :sap_config__db__password => "DB User Password",
#TODO: for below should be way to parse with wild card 
  :sap_config__db__admin__name => "Admin DB Name",
  :sap_config__db__admin__owner => "DB Admin User",
  :sap_config__db__admin__password => "DB Admin Password",
  :sap_ref_to_master => "Master Reference",

#TODO: temp until finding normal local for all attribute labels
#JMX related
  :jmxremote_port => 'JMX Remote Port',
  :jmxremote_password => 'JMX Remote Password',

#mysql
  :mysql__server_root_password => 'Server Root Pwrd',
  :mysql__tunable_net_read_timeout => 'Net Read Timeout',
  :mysql__tunable_wait_timeout => 'Wait Timeout',
  :mysql__tunable_max_heap_table_size => 'Max Heap Table Size',
  :mysql__tunable_key_buffer => 'Key Buffer',
  :mysql__tunable_net_write_timeout => 'Net Write Timeout',
  :mysql__tunable_max_connections => 'Max Connections',
  :mysql__tunable_table_cache => 'Table Cache',
  :mysql__tunable_back_log => 'Back Log',
  :mysql__ec2_path => 'EC2 Path',
  :mysql__bind_address => 'Bind Address',
  :mysql__db_info => 'DB Info',
  :mysql__monitor_user_id => 'Monitor Usr ID',
  :mysql__datadir => 'Data Dir',
  :mysql__master_log => "Master Log",
  :mysql__master_log_ref => "Master Log Ref",
  :mysql__sap_ref_to_master => "SAP Ref to Master",
  :mysql__sap_config_for_slave => "SAP Config for Slave",

#mysql slave
  :master_log_ref=>"Master Log Ref",

#postgresql
  :postgresql__dir => "PostgreSQL Directory",
  :conns_to_real_dbs__port => "DB Conn Port",
  :conns_to_real_dbs__protocol => "DB Conn Proto",
  :conns_to_real_dbs__host_address => "DB Conn Addr",
#user_account
  :user_account__username => "User Name",
  :user_account__uid => "User ID",
  :user_account__gid => "User's Group ID",

#apache2
 :apache2__servertokens=>"Server Tokens",
 :apache2__dir=>"Directory",
 :apache2__contact=>"Contact",
 :apache2__serversignature=>"Server Signature",
 :apache2__log_dir=>"Log Directory",
 :apache2__timeout=>"Timeout",
 :apache2__user=>"User",
 :apache2__keepalive=>"Keepalive",
 :apache2__binary=>"Binary",
 :apache2__keepaliverequests=>"Keepalive Requests",
 :apache2__icondir=>"Icondir",
 :apache2__keepalivetimeout=>"Keepalive Timeout",
 :apache2__listen_ports=>"Listen Ports",

#wordpress
 :db__user=>"DB Username",
 :db__password=>"DB Password",
 :dir=> "App Directory",
 :checksum=>"Checksum",
 :keys__nonce=>"Keys Nonce",
 :keys__logged_in=>"Keys Logged In",
 :version=>"Version",
 :keys__auth=>"Keys Auth",
 :keys__secure_auth=>"Keys Secure Auth",

 :wordpress__dir=>"Installation Directory",
 :wordpress__keys_logged_in=>"Logged-in Key",
 :wordpress__db_database=>"MySQL Database",
 :wordpress__keys_nonce=>"Nonce Key",
 :wordpress__db_user=>"MySQL User",
 :wordpress__db_password=>"MySQL password",
 :wordpress__version=>"Download Version",
 :wordpress__keys_auth=>"Auth Key",
 :wordpress__checksum=>"Tarball Checksum",
 :wordpress__keys_secure_auth=>"Secure Auth Key",

#haproxy
 :conns_to_real_servers__host_address => "Real Server Addr",
 :conns_to_real_servers__port => "Real Server Port",
 :conns_to_real_servers__protocol => "Real Server Proto",

#nagios
  :nagios__monitored_client_sap_config => "SAP Config",
  :nagios__monitor_sap_refs => "NRPE SAP Refs",
}
