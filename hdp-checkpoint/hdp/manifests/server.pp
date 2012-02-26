class hdp-hcat::server(
  $server_state = 'running',
  $ganglia_host = undef,
  $nagios_host = undef,
  $opts = {}
)
{
    
  class{ 'hdp-hcat' : server => true} #installs package, creates user, sets configuration
  
  Hdp-Hcat::Configfile<||>{hcat_server_host => $hdp::params::host_address}

  class { 'hdp-hcat::hdfs-directories' : }

  class { 'hdp-hcat::service' :
    enable       => $server_state,
    initial_wait => $opts[wait]
  }
  #top level does not need anchors

  Class['hdp-hcat'] -> Class['hdp-hcat::hdfs-directories'] -> Class['hdp-hcat::service']
}

class hdp-hcat::hdfs-directories()
{
  #TODO: need to make sure that hdfs service is running
  #TODO: change
  #Hdp-hcat::Hdfs::Directory['/mapred'] -> Hdp-hcat::Hdfs::Directory['/mapred/system'] 
}
