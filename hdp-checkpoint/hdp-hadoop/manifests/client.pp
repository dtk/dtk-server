class hdp-hadoop::client()
{
  #assumption that if this on on node, no other hadoop roles will be on node
  class { 'hdp-hadoop': } #adds package, users, directories, and common configs
  
  $hdfs_user = $hdp-hadoop::params::hdfs_user
  hdp-hadoop::client::configfile { 'hdfs-site.xml': owner => $hdfs_user}

  #top level does not need anchors
  Class['hdp-hadoop'] ->  Hdp-hadoop::Client::Configfile<||> 
}

define hdp-hadoop::client::configfile(
  $owner
)
{
  hdp-hadoop::configfile { $name: owner => $owner} 
}
