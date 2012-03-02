class hdp-nagios::server::packages()
{
  package { ['httpd','php','net-snmp-perl','perl-Net-SNMP'] : }
  hdp-nagios::server::package { ['perl_net_snmp','server','fping','plugins']: } 

  #TODO: ccnflict if other modules load in packages httpd','php','net-snmp-perl','perl-Net-SNMP in stage after this
  anchor{'hdp-nagios::server::packages::begin':}  -> Hdp-nagios::Server::Package<||> -> anchor{'hdp-nagios::server::packages::end':}
  Package['php'] -> Hdp-nagios::Server::Package['server']
  Hdp-nagios::Server::Package['perl_net_snmp'] -> Hdp-nagios::Server::Package['plugins']
  Hdp-nagios::Server::Package['fping'] -> Hdp-nagios::Server::Package['plugins']
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
