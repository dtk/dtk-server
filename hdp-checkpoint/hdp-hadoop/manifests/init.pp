class hdp-hadoop()
{
  hdp::package{ 'hadoop' : included => true}
  include hdp-hadoop::users
  include hdp-hadoop::directory
  include hdp-hadoop::common-configfiles
 
  anchor{'hdp-hadoop::begin' :} -> Hdp::Package['hadoop'] -> Class['hdp-hadoop::directory'] -> Class['hdp-hadoop::common-configfiles'] -> anchor{ 'hdp-hadoop::end':}
  Anchor['hdp-hadoop::begin'] -> Class['hdp-hadoop::users'] -> Class['hdp-hadoop::common-configfiles'] 
}
#using define vs class because cannot uses class in collect statement
#$namenode is used for conditional ordering in componet role classes
#only realized under 1 name
define hdp-hadoop::common($namenode = false)
{
 include hdp-hadoop
 anchor{'hdp-hadoop::common::begin' :} -> Class['hdp-hadoop'] -> anchor{'hdp-hadoop::common::end' :}
}


### users and groups
class hdp-hadoop::users() 
{
  include hdp-hadoop::params
  $hdf_user = $hdp-hadoop::params::hdfs_user
  $mapred_user = $hdp-hadoop::params::mapred_user

  hdp::user{ $hdf_user:}
  if ($hdf_user == $mapred_user) {}
  else {
    hdp::user { $mapred_user:}
  }
}

class hdp-hadoop::directory()
{  
 include hdp-hadoop::params
 hdp::directory { $hdp-hadoop::params::conf_dir:}
}

### config files
class hdp-hadoop::common-configfiles()
{
  anchor { 'hdp-hadoop::common-configfiles::begin' :}
  anchor { 'hdp-hadoop::common-configfiles::end' :}
  Anchor['hdp-hadoop::common-configfiles::begin'] -> hdp-hadoop::configfile { 'hadoop-env.sh': } -> Anchor['hdp-hadoop::common-configfiles::end']
  Anchor['hdp-hadoop::common-configfiles::begin'] -> hdp-hadoop::configfile { 'core-site.xml': } -> Anchor['hdp-hadoop::common-configfiles::end']
}

###config file helper
define hdp-hadoop::configfile(
  $owner = undef,
  $hadoop_conf_dir = $hdp-hadoop::params::conf_dir,
  $mode = undef,
  $namenode_host = undef,
  $jtnode_host = undef,
  $snamenode_host = undef
) 
{
 
  if ($jtnode_host == undef) {
    $calc_jtnode_host = $namenode_host
  } else {
    $calc_jtnode_host = $jtnode_host 
  }
 
  hdp::configfile { $name:
    component      => 'hadoop',
    owner          => $owner,
    conf_dir       => $hadoop_conf_dir,
    mode           => $mode,
    namenode_host  => $namenode_host,
    snamenode_host => $snamenode_host,
    jtnode_host    => $calc_jtnode_host
  }
}

#####
define hdp-hadoop::exec-hadoop(
  $command,
  $unless = undef
)
{
  include hdp-hadoop::params
  hdp::exec { "hadoop ${command}":
    command => "hadoop ${command}",
    user    => $hdp-hadoop::params::hdfs_user,
    unless  => $unless
  }
}

  