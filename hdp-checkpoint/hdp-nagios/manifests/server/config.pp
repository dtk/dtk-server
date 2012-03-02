class hdp-nagios::server::config($targets)
{
  hdp-nagios::server::configfile { 'nagios.cfg' : }
  #TODO: .. put in rest
  
  hdp-nagios::server::config::hostgroup { 'all-servers': targets => $targets, alias_name => "All Servers"}
  hdp-nagios::server::config::hostgroup { 'namnode': host_type => 'namnode_host'}
  #TODO: .. put in rest
  hdp-nagios::server::config::host{$targets : }
  #TODO: .. put in rest
  
  anchor{'hdp-nagios::server::config::begin':} -> Hdp-nagios::Server::Configfile<||> -> anchor{'hdp-nagios::server::config::end':}
  Anchor['hdp-nagios::server::config::begin'] -> Hdp-nagios::Server::Config::Hostgroup<||> -> Anchor['hdp-nagios::server::config::end']
  Anchor['hdp-nagios::server::config::begin'] -> Hdp-nagios::Server::Config::Host<||> -> Anchor['hdp-nagios::server::config::end']
}

define hdp-nagios::server::config::host()
{
  nagios_host { $name:
    address => $name,
    alias   => $name,
    use     => 'linux-server'
  }
}

define hdp-nagios::server::config::hostgroup(
  $host_type = undef,
  $targets = undef,
  $alias_name = undef
)
{

  if ($alias_name == undef) {
    $alias = $name
  } else {
    $alias = $alias_name
  }
    
  if ($targets == undef) {
    $members = inline_template("<%= h=scope.function_hdp_host('${host_type}'); h.empty? ? '' : [h].flatten(1).split(',')%>") 
  } else {
    $members = $targets
  }
  if ("" != $members) {      
    nagios_hostgroup { $name:
      members => $members,
      alias   => $alias
    }
  }
}

###config file helper
define hdp-nagios::server::configfile(
  $owner = undef,
  $mode = undef 
) 
{
  
  hdp::configfile { $name:
    component      => 'nagios',
    owner          => $owner,
    conf_dir       => $hdp-nagios::params::conf_dir,
    mode           => $mode
  }
}