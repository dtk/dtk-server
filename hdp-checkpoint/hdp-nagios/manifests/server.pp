 class hdp-nagios::server($monitored_hosts = undef)
{
  include hdp-nagios::params

  if ($monitored_hosts == undef) {
    $types = "namenode_host,datanode_hosts,jtnode_host,ttnode_hosts,snamenode_host,zookeeper_hosts,hbase_master_host,hbase_rs_hosts,hcat_server_host"
    $targets = hdp_nagios_target_hosts($types)
  } else {	     
    $targets = $monitored_hosts
  }

  package { ['httpd','php','net-snmp-perl','perl-Net-SNMP'] : }
  hdp-nagios::server::package { ['perl_net_snmp','server','fping','plugins']: } 
  
  hdp-nagios::server::host{$targets : }

  Hdp-nagios::Server::Package<||> -> Hdp-nagios::Server::Host<||>
  Package['php'] -> Hdp-nagios::Server::Package['server']
  Hdp-nagios::Server::Package['perl_net_snmp'] -> Hdp-nagios::Server::Package['plugins']
  Hdp-nagios::Server::Package['fping'] -> Hdp-nagios::Server::Package['plugins']
}

define hdp-nagios::server::host()
{
  nagios_host { $name:
    address => $name,
    alias   => $name,
    use     => 'linux-server'
  }
}

define hdp-nagios::server::package()
{
  $info = $hdp-nagios::params::nagios_download_info[$name]  
  $target = "/tmp/${info[rpm]}"
  
  $wget_cmd = "wget ${info[url]} -O ${target}"
  exec { $wget_cmd:
    command => $wget_cmd,
    path    => ["/usr/bin/"],
    creates => $target
  }
   
  $install_cmd = $info[provider] ? {
    'yum'  => "yum -y ${info[options]} install ${target}",
    'rpm' => "rpm ${info[options]} -i ${target}",
     default  => undef,
  }

  exec { $install_cmd:
    command => $install_cmd,
    path    => ["/bin","/usr/bin/"],
    creates => $info[creates]
  }
 
  anchor{"hdp-nagios::server::package::${name}::begin":} -> Exec[$wget_cmd] -> Exec[$install_cmd] -> anchor{"hdp-nagios::server::${name}::package::end":}
}
