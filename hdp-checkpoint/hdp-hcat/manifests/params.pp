class hdp-hcat::params() inherits hdp::params
{

  #TODO: will move to globals
  $hcat_metastore_user_name = hdp_default("hadoop/hive-site/hcat_metastore_user_name","dbusername")

  $hcat_metastore_user_passwd = hdp_default("hadoop/hive-site/hcat_metastore_user_passwd","dbpassword")

  $hcat_mysql_server = hdp_default("hadoop/hive-site/hcat_mysql_server","ec2-50-19-230-130.compute-1.amazonaws.com")
 
 ####### users
  $hcat_user = hdp_default("hcat_user","hcat")
  
  ### common
  $hcat_metastore_port = hdp_default("hcat_metastore_port",9933)
  $hcat_lib = hdp_default("hcat_lib","/usr/share/hcatalog/lib") #TODO: should I remove and just use hcat_dbroot

  ### hcat-env
  $hcat_conf_dir = hdp_default("hadoop/hcat-env/hcat_conf_dir","/etc/hcatalog")

  $hcat_dbroot = hdp_default("hadoop/hcat-env/hcat_dbroot",$hcat_lib)

  $hcat_logdirprefix = hdp_default("hadoop/hcat-env/hcat_logdirprefix","/var/log")
  $hcat_log_dir = "${hcat_logdirprefix}/${hcat_user}"

  $hcat_piddirprefix = hdp_default("hadoop/hcat-env/hcat_piddirprefix","/usr/pids")
  $hcat_pid_dir = "${hcat_piddirprefix}/${hcat_user}"
  
  ### hive-site
  $hcat_database_name = hdp_default("hadoop/hive-site/hcat_database_name","hive")

  $hcat_metastore_principal = hdp_default("hadoop/hive-site/hcat_metastore_principal")

  $hcat_metastore_sasl_enabled = hdp_default("hadoop/hive-site/hcat_metastore_sasl_enabled")

  $hcat_metastore_server_host = hdp_default("hadoop/hive-site/hcat_metastore_server_host","0.0.0.0") #TODO: just works for server

  $keytab_path = hdp_default("hadoop/hive-site/keytab_path")
  
  ###mysql connector
  $mysql_zip_name = hdp_default("hcat_mysql_zip_name","mysql-connector-java-5.1.18.zip")
  $mysql_connector_url = hdp_default("hcat_mysql_connector","http://mysql.he.net/Downloads/Connector-J/${mysql_zip_name}")
}
