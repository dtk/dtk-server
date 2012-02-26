class hdp-hadoop::jobtracker(
  $service_state = 'running',
  $ganglia_host = undef,
  $nagios_host = undef,
  $opts = {}
)
{
    
  include hdp::params
  
  Hdp-Hadoop::Configfile<||>{jtnode_host => $hdp::params::host_address}
  #mapred config files
  hdp-hadoop::jobtracker::configfile { 'mapred-site.xml': }

  class { 'hdp-hadoop::jobtracker::directory' : }
  
  hdp-hadoop::service{ 'jobtracker':
    enable       => $service_state,
    user         => $hdp-hadoop::params::mapred_user,
    initial_wait => $opts[wait]
  }
  #TODO: to support jt on different node than namenode may need to use virtual resource for Hdp-hadoop::Common
  #top level does not need anchors
  Hdp-hadoop::Common<|namenode == false|> -> Hdp-hadoop::Jobtracker::Configfile<||> -> Hdp-hadoop::Service['jobtracker']
  Class['hdp-hadoop::jobtracker::directory'] -> Hdp-hadoop::Service['jobtracker']
}

class hdp-hadoop::jobtracker::directory()
{
  #TODO: need to make sure that hdfs service is running
  hdp-hadoop::hdfs::directory{ '/mapred' :
    owner => $hdp-hadoop::params::mapred_user
  }  
   hdp-hadoop::hdfs::directory{ '/mapred/system' :
    owner => $hdp-hadoop::params::mapred_user
  }  
  Hdp-hadoop::Hdfs::Directory['/mapred'] -> Hdp-hadoop::Hdfs::Directory['/mapred/system'] 
}

define hdp-hadoop::jobtracker::configfile()
{
  hdp-hadoop::configfile { $name: owner => $hdp-hadoop::params::mapred_user}
}