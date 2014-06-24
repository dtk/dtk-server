
{
  :id => 'ID',
  :display_name => 'Name',
  :description => 'Description',
  :external_type => 'External Type',
  :external_ref => 'External Component Ref',
  :type => 'Type',
  :basic_type => 'Basic Type',
  :version => 'Version',
  :uri => 'Uri',
  :parent_name => 'Parent',
  :containing_datacenter => 'Datacenter',
  :only_one_per_node => '1 Per Node',
  :has_pending_change => 'Pending Change',
  :ui => 'UI',
  :updated_at => 'Date Modified',
  :created_at => 'Date Created',
  :description_list => 'Descr',
  :external_ref_list => 'Ext Component Ref',


#------------------------------------------
  :components => 'Components',
  :no_attributes => 'No Attributes',

  :actions => 'Actions',
  :details => 'Details',
# temp for testing
  :instance => 'Instance',

# temp strings for component names
  :hadoop => 'Hadoop',
  :hadoop_hive => 'Hadoop Hive',
  :hadoop_doc => 'Hadoop Docs',
  :hadoop__ssh_auth_key => "SSH Auth Key",
  :hadoop_cloudera_c3 => 'Cloudera C3',
  :hadoop_cloudera_c3__conf_pseudo => 'Pseudo Conf',
  :rabbitmq_edge_stomp => 'Rabbit - Stomp',
  :mysql_server2 => 'MySQL Server',
  :mysql_server => 'MySQL Server',
  :mysql_slave => 'MySQL Slave',
  :mysql_master => 'MySQL Master',
  :user_account => "User Account",
  :redis => "Redis",
  :apache2 => "Apache2",
  :php_php5 => "Php5",
  :postgresql_client => "Postgres Client",
  :postgresql_server => "Postgres Server",
  :postgresql_app => "Postgres App",
  :wordpress => "Wordpress",
  :nagios_client => "NRPE",
  :nagios_server => "Nagios3 Server",

# TODO: replace above with new form
  :hadoop__hive => 'Hadoop Hive',
  :hadoop__doc => 'Hadoop Docs',
  :rabbitmq__edge_stomp => 'Rabbit - Stomp',
  :mysql__server2 => 'MySQL Server',
  :mysql__server => 'MySQL Server',
  :mysql__slave => 'MySQL Slave',
  :mysql__master => 'MySQL Master',
  :php__php5 => "Php5",
  :postgresql__client => "Postgres Client",
  :postgresql__server => "Postgres Server",
  :postgresql__pgpool => "Pgpool",
  :postgresql__app => "Postgres App",
  :nagios__client => "NRPE",
  :nagios__server => "Nagios3 Server",

#### test for user accounts
  :user_account_tom => "Tom",
  :user_account_rich => "Rich",
  :user_account_nate => "Nate",

## HDP
###### hadoop
  "hdp-hadoop__namenode-conn".to_sym => "NN conn",
  "hdp-hadoop__namenode".to_sym => "Namenode",
  "hdp-hadoop__jobtracker".to_sym => "Jobtracker",
  "hdp-hadoop__tasktracker".to_sym => "Tasktracker",
  "hdp-hadoop__datanode".to_sym => "Datanode",
#### zoookeeper
  "hdp-zookeeper".to_sym => "ZK",
  "hdp-zookeeper__quorom-member".to_sym => "ZK member",
### hbase
  "hdp-hbase__zk-conn".to_sym => "Hbase ZK conn",
  "hdp-hbase__master".to_sym => "Hbase Master",
  "hdp-hbase__master-conn".to_sym => "Hbase Master conn",
  "hdp-hbase__regionserver".to_sym => "Hbase Region Server",
}

