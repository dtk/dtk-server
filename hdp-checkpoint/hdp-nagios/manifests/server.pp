 class hdp-nagios::server(
   $service_state = 'running',
   $monitored_hosts = undef) 
{
  include hdp-nagios::params

  #TODO: optionally pass in targets which is has taht goes role of each address
  if ($monitored_hosts == undef) {
    #TODO: make sure list is in sync (with hdp::params host def and includes everything monitored
    $types = [namenode_host,datanode_hosts,jtnode_host,slave_hosts,snamenode_host,zookeeper_hosts,hbase_master_host,gateway_host,hcat_server_host]
    $targets = hdp_nagios_target_hosts($types)
  } else {	     
    $targets = $monitored_hosts
  }

  class { 'hdp-nagios::server::packages' :}

  class { 'hdp-nagios::server::config': targets => $targets}

  class { 'hdp-nagios::server::web_permisssions': }

  class { 'hdp-nagios::server::services': ensure => $service_state}

  Class['hdp-nagios::server::packages'] -> Class['hdp-nagios::server::config'] -> 
   Class['hdp-nagios::server::web_permisssions'] -> Class['hdp-nagios::server::services']
}

class hdp-nagios::server::web_permisssions()
{
  $web_login = $hdp-nagios::params::nagios_web_login
  $cmd = "htpasswd -c -b  /etc/nagios/htpasswd.users ${web_login} ${hdp-nagios::params::nagios_web_password}"
  $test = "grep ${web_user} /etc/nagios/htpasswd.users"
  hdp::exec { $cmd :
    command => $cmd,
    unless => $test
  }
}

class hdp-nagios::server::services($ensure)
{
  service { ['httpd','nagios']: ensure => $ensure}
  
  anchor{'hdp-nagios::server::services::begin':} -> Service['httpd'] -> Service['nagios'] ->  anchor{'hdp-nagios::server::services::end':}
}
