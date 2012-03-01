class hdp-hadoop::tasktracker(
  $service_state = 'running',
  $ganglia_host = undef,
  $nagios_host = undef,
  $opts = {}
) 
{
  include hdp-hadoop #adds package, users, directories, and common configs

  hdp-hadoop::service{ 'tasktracker':
    enable       => $service_state,
    user         => $hdp-hadoop::params::mapred_user,
    initial_wait => $opts[wait]
  }
  
  #top level does not need anchors
  Class['hdp-hadoop'] -> Hdp-hadoop::Service['tasktracker']
}
