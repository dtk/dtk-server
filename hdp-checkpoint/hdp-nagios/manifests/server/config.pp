class hdp-nagios::server::config($targets)
{

  $host_cfg = $hdp-nagios::params::nagios_host_cfg
  
  #TODO: may make nagios-hadoop-services.cfg .. params also
  hdp-nagios::server::configfile { 'nagios.cfg': conf_dir => $hdp-nagios::params::conf_dir }
  hdp-nagios::server::configfile { 'nagios-hadoop-hosts.cfg': }
  hdp-nagios::server::configfile { 'nagios-hadoop-hostgroups.cfg': }
  hdp-nagios::server::configfile { 'nagios-hadoop-services.cfg': }
  hdp-nagios::server::configfile { 'nagios-hadoop-commands.cfg': }
  #TODO: .. put in rest

  anchor{'hdp-nagios::server::config::begin':} -> Hdp-nagios::Server::Configfile<||> -> anchor{'hdp-nagios::server::config::end':}
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