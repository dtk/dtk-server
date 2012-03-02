 class hdp-nagios::server($monitored_hosts = undef)
{
  include hdp-nagios::params

  if ($monitored_hosts == undef) {
    $types = "namenode_host,datanode_hosts,jtnode_host,ttnode_hosts,snamenode_host,zookeeper_hosts,hbase_master_host,hbase_rs_hosts,hcat_server_host"
    $targets = hdp_nagios_target_hosts($types)
  } else {	     
    $targets = $monitored_hosts
  }

  class { 'hdp-nagios::server::package': }

  hdp-nagios::server::host{$targets : }

  Class['hdp-nagios::server::package'] -> Hdp-nagios::Server::Host<||>

}

define hdp-nagios::server::host()
{
  nagios_host { $name:
    address => $name,
    alias   => $name,
    use     => 'linux-server'
  }
}
class hdp-nagios::server::package()
{
  $target = "/tmp/nagiosserver.rpm"
  $nagios_exec = "/usr/bin/nagios"  

  $wget_cmd = "wget ${hdp-nagios::params::nagios_rpm_url} -O ${target}"
  exec { $wget_cmd:
    command => $wget_cmd,
    path    => ["/usr/bin/"],
    creates => $target,
    unless  => "test -e ${nagios_exec}"
  }

  $install_cmd = "yum -y --nogpgcheck install ${target}"
  exec { $install_cmd:
    command => $install_cmd,
    path    => ["/bin","/usr/bin/"],
    creates => $nagios__exec
  }
 
  anchor{'hdp-nagios::server::package::begin':} -> Exec[$wget_cmd] -> Exec[$install_cmd] -> anchor{'hdp-nagios::server::package::end':}
}
