class hdp-hadoop()
{
  include hdp-hadoop::params

  $conf_dir = $hdp-hadoop::params::conf_dir
  $mapred_user = $hdp-hadoop::params::mapred_user  
  $hdfs_user = $hdp-hadoop::params::hdfs_user  

  hdp::package{ 'hadoop' : included => true}

  hdp::user{ $hdfs_user:}
  hdp::user { $mapred_user:}

  hdp::directory { $conf_dir:}
 
  hdp-hadoop::configfile { 'hadoop-env.sh': context_tag => common, owner => $hdfs_user}
  hdp-hadoop::configfile { 'core-site.xml': context_tag => common, owner => $hdfs_user}
  hdp-hadoop::configfile { 'hdfs-site.xml': context_tag => common, owner => $hdfs_user}
  hdp-hadoop::configfile { 'mapred-site.xml': context_tag => common, owner => $mapred_user}

  anchor{'hdp-hadoop::begin':} -> Hdp::Package['hadoop'] ->  Hdp::User<|title == $hdfs_user or title == $mapred_user|> 
  -> Hdp::Directory[$conf_dir] -> Hdp-hadoop::Configfile<|context_tag == 'common'|> -> anchor{ 'hdp-hadoop::end':}
}

#using define vs class because cannot uses class in collect statement
#$namenode is used for conditional ordering in componet role classes
#only realized under 1 name
define hdp-hadoop::common($namenode = false)
{
 include hdp-hadoop
 anchor{'hdp-hadoop::common::begin' :} -> Class['hdp-hadoop'] -> anchor{'hdp-hadoop::common::end' :}
}

###config file helper
define hdp-hadoop::configfile(
  $owner = undef,
  $hadoop_conf_dir = $hdp-hadoop::params::conf_dir,
  $mode = undef,
  $namenode_host = undef,
  $jtnode_host = undef,
  $snamenode_host = undef,
  $context_tag = undef
) 
{
  #TODO: may need to be fixed 
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

  