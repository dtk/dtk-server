class hdp-nagios::server::config($targets)
{

  $host_cfg = $hdp-nagios::params::nagios_host_cfg
  $hostgroup_cfg = $hdp-nagios::params::nagios_hostgroup_cfg
  
  #TODO: may make nagios-hadoop-services.cfg .. paarms also
  hdp-nagios::server::configfile { 'nagios.cfg': conf_dir => $hdp-nagios::params::conf_dir }
  hdp-nagios::server::configfile { 'nagios-hadoop-services.cfg': }
  hdp-nagios::server::configfile { 'nagios-hadoop-commands.cfg': }
  #TODO: .. put in rest
  
  #TODO: !!!all-servers does not work with targets == undef
  hdp-nagios::server::config::hostgroup { 'all-servers': targets => $targets, alias_name => "All Servers"}
  hdp-nagios::server::config::hostgroup { 'namenode': host_type => 'namenode_host'}
  hdp-nagios::server::config::hostgroup { 'slaves': host_type => 'slave_hosts'}
  hdp-nagios::server::config::hostgroup { 'nagios-server': host_type => 'nagios_server_host'}
  hdp-nagios::server::config::hostgroup { 'jobtracker': host_type => 'jtnode_host'}
  hdp-nagios::server::config::hostgroup { 'ganglia-server': host_type => 'ganglia_server_host'}
  #TODO: .. put in rest
  
  
  hdp-nagios::server::config::host{$targets : }
  hdp-nagios::server::config::host{'dev-null' : } #TODO: hack to get aroudn empty host groups
  #TODO: .. put in rest
  
  anchor{'hdp-nagios::server::config::begin':} -> Hdp-nagios::Server::Configfile<||> -> anchor{'hdp-nagios::server::config::end':}
  Anchor['hdp-nagios::server::config::begin'] -> Hdp-nagios::Server::Config::Hostgroup<||> -> hdp-nagios::server::config::cfg_file{$hostgroup_cfg:} -> Anchor['hdp-nagios::server::config::end']
  Anchor['hdp-nagios::server::config::begin'] -> Hdp-nagios::Server::Config::Host<||> -> hdp-nagios::server::config::cfg_file{$host_cfg:} -> Anchor['hdp-nagios::server::config::end']
}

#used because puppet nagios resources do not set owner/group
define hdp-nagios::server::config::cfg_file()
{
  file { $name :
    owner => $hdp-nagios::params::nagios_user,
    group => $hdp-nagios::params::nagios_group
  }
}    

define hdp-nagios::server::config::host()
{
  nagios_host { $name:
    address => $name,
    alias   => $name,
    use     => 'linux-server',
    target  => $hdp-nagios::params::nagios_host_cfg
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
      #TODO: fix: empty hostgroups
    $members = inline_template("<%= h=scope.function_hdp_host('${host_type}'); h.empty? ? 'dev-null' : [h].flatten(1).join(',')%>") 
  } else {
    $members = $targets
  }
  if ("" != $members) {  
    nagios_hostgroup { $name:
      members => $members,
      alias   => $alias,
      target  => $hdp-nagios::params::nagios_hostgroup_cfg
    }
  }
}

###config file helper
define hdp-nagios::server::configfile(
  $owner = $hdp-nagios::params::nagios_user,
  $conf_dir = $hdp-nagios::params::nagios_obj_dir,
  $mode = undef 
) 
{
  
  hdp::configfile { $name:
    component      => 'nagios',
    owner          => $owner,
    conf_dir       => $conf_dir,
    mode           => $mode
  }
}