class hdp-hbase::master(
  $service_state = running,
  $ganglia_host = undef,
  $nagios_host = undef,
  $opts = {}
) 
{
  include hdp-hbase::params
  $hdfs_root_dir = $hdp-hbase::params::hbase_hdfs_root_dir
  
  $hdp::params::service_exists['hdp-hbase::master'] = true
  
  hdp-hbase::common { 'hbase': master => true} #adds package, users, directories, and common configs
  Hdp-hbase::Configfile<||>{hbase_master_host => $hdp::params::host_address}
  
  hdp-hadoop::hdfs::directory { $hdfs_root_dir:
   owner => $hdp-hbase::params::hbase_user
  }  
  
  hdp-hbase::service{ 'master':
    ensure       => $service_state,
    initial_wait => $opts[wait]
  }

  #top level does not need anchors
  Hdp-hbase::Common['hbase'] -> Hdp-hadoop::Hdfs::Directory[$hdfs_root_dir] -> Hdp-hbase::Service['master']
}
