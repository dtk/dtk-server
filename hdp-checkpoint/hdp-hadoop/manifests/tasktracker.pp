class hdp-hadoop::tasktracker(
  $service_state = 'running',
  $ganglia_host = undef,
  $nagios_host = undef,
  $opts = {}
) 
{
  include hdp-hadoop #adds package, users, directories, and common configs

  hdp-hadoop::tasktracker::configfile { 'mapred-site.xml':}

  hdp-hadoop::service{ 'tasktracker':
    enable       => $service_state,
    user         => $hdp-hadoop::params::mapred_user,
    initial_wait => $opts[wait]
  }
  
  #top level does not need anchors
  Class['hdp-hadoop'] -> Hdp-hadoop::Tasktracker::Configfile<||>  -> Hdp-hadoop::Service['tasktracker']
}

define hdp-hadoop::tasktracker::configfile()
{
  hdp-hadoop::configfile { $name: owner => $hdp-hadoop::params::mapred_user}
}