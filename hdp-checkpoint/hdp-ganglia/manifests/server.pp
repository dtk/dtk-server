class hdp-ganglia::server($monitored_hosts = undef) 
{
  include hdp-ganglia::params

  class { 'hdp-ganglia::server::packages': }
}


class hdp-ganglia::old-server($monitored_hosts = undef) 
{
  include hdp-ganglia::params

  if ($monitored_hosts == undef) {
    #TODO: make sure list is in sync (with hdp::params host def and includes everything monitored
    $types = [namenode_host,datanode_hosts,jtnode_host,slave_hosts,snamenode_host,zookeeper_hosts,hbase_master_host,gateway_host,hcat_server_host]
    $targets = hdp_ganglia_target_hosts($types)
  } else {	     
    $targets = $monitored_hosts
  }

  class { 'hdp-ganglia::server::packages' :}
  class { 'hdp-ganglia::server::config': targets => $targets}

  Class['hdp-ganglia::server::packages'] -> Class['hdp-ganglia::server::config']
}

class hdp-ganglia::server::packages()
{
  hdp::package { ['ganglia-monitor','ganglia-server','ganglia-gweb','ganglia-hdp-gweb-addons'] : provider => 'yum'}
}
