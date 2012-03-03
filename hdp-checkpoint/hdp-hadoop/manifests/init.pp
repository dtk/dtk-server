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
  $unless = undef,
  $echo_yes = false
)
{
  include hdp-hadoop::params
  if ($echo_yes == true) {
    $cmd = "echo Y | hadoop ${command}"
  } else {
    $cmd = "hadoop ${command}"       
  }
  hdp::exec { $cmd:
    command => $cmd,
    user    => $hdp-hadoop::params::hdfs_user,
    unless  => $unless
  }
}

  