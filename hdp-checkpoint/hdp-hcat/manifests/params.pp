class hdp-hcat::params() inherits hdp::params
{

  ####### users
  $hcat_user = hdp_default("hcat_user","hcat")
  
  ### common
  $hcat_metastore_port = hdp_default("hcat_metastore_port",9933)

  ### hcat-env
  $conf_dir = hdp_default("hadoop/hcat-env/hcat_conf_dir","/etc/hcatalog")

  $hcat_dbroot = hdp_default("hadoop/hcat-env/hcat_dbroot")

  $hcat_logdirprefix = hdp_default("hadoop/hcat-env/hcat_logdirprefix","/var/log")
  $hcat_log_dir = "${hcat_logdirprefix}/${hcat_user}"

  $hcat_piddirprefix = hdp_default("hadoop/hcat-env/hcat_piddirprefix","/usr/pids")
  $hcat_pid_dir = "${hcat_piddirprefix}/${hcat_user}"
  
  ### hive-site
  $hcat_database_name = hdp_default("hadoop/hive-site/hcat_database_name")

  $hcat_metastore_principal = hdp_default("hadoop/hive-site/hcat_metastore_principal")

  $hcat_metastore_sasl_enabled = hdp_default("hadoop/hive-site/hcat_metastore_sasl_enabled")

  $hcat_metastore_server_host = hdp_default("hadoop/hive-site/hcat_metastore_server_host")

  $hcat_metastore_user_name = hdp_default("hadoop/hive-site/hcat_metastore_user_name")

  $hcat_metastore_user_passwd = hdp_default("hadoop/hive-site/hcat_metastore_user_passwd")

  $hcat_mysql_server = hdp_default("hadoop/hive-site/hcat_mysql_server")

  $keytab_path = hdp_default("hadoop/hive-site/keytab_path")

}
