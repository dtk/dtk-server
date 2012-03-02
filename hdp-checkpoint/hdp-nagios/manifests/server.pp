 class hdp-nagios::server($monitored_hosts = undef)
{
  include hdp::params
  if ($monitored_hosts == undef) {
    $types = "namenode_host,datanode_hosts,jtnode_host,ttnode_hosts,snamenode_host,zookeeper_hosts,hbase_master_host,hbase_rs_hosts,hcat_server_host"
    $targets = hdp_nagios_target_hosts($types)
  } else {	     
    $targets = $monitored_hosts
  }
  hdp-nagios::server::host{$targets : }
}

define hdp-nagios::server::host()
{
  nagios_host { $name:
    address => $name,
    alias   => $name,
    use     => 'linux-server'
  }
}
