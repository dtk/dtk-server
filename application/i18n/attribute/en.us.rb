
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
  :sap_ipv4 => 'SAP IPV4',
  :sap_config_ipv4 => 'SAP Config IPV4',
  :sap_socket => 'SAP Socket',

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
  :mysql__sap_ref_to_master => "Sap Ref to Master",

#postgresql
  :postgresql__dir => "PostgreSQL Directory",
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
}
