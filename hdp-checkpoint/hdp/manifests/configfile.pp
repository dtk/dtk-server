define hdp::configfile(
  $component,
  $conf_dir,
  $owner = undef,
  $mode = undef,
  $size = 64, #32 or 64 bit (used to pick appropriate java_home)
  $namenode_host = $hdp::params::namenode_host,
  $jtnode_host = $hdp::params::jtnode_host,
  $snamenode_host = $hdp::params::snamenode_host,
  $zookeeper_hosts = $hdp::params::zookeeper_hosts,
  $hbase_master_host = $hdp::params::hbase_master_host,
  $hcat_server_host = $hdp::params::hcat_server_host,
  $hcat_mysql_host = $hdp::params::hcat_mysql_host
) 
{
   $file_name = "${conf_dir}/${name}"
  
   $template_name = "hdp-${component}/${name}.erb"
   hdp::file{ $file_name:
     ensure  => present,
     owner   => $owner,
     mode    => $mode,
     content => template($template_name)
  }
}
