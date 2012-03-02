 class hdp-nagios::server($monitored_hosts = undef) 
{
  include hdp-nagios::params

  if ($monitored_hosts == undef) {
    #TODO: make sure list is in sync (with hdp::params host def and includes everything monitored
    $types = [namenode_host,datanode_hosts,jtnode_host,slave_hosts,snamenode_host,zookeeper_hosts,hbase_master_host,gateway_host,hcat_server_host]
    $targets = hdp_nagios_target_hosts($types)
  } else {	     
    $targets = $monitored_hosts
  }

  class { 'hdp-nagios::server::packages' :}
  class { 'hdp-nagios::server::config': targets => $targets}

  Class['hdp-nagios::server::packages'] -> Class['hdp-nagios::server::config']
}


