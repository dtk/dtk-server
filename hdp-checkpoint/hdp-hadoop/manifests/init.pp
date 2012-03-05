class hdp-hadoop(
  $ganglia_enabled = false
)
{
  include hdp-hadoop::params

  $conf_dir = $hdp-hadoop::params::conf_dir
  $mapred_user = $hdp-hadoop::params::mapred_user  
  $hdfs_user = $hdp-hadoop::params::hdfs_user  
  if ($ganglia_enabled == false) {
    $hadoop-metrics2_tag = undef
  } else {
    $hadoop-metrics2_tag = 'GANGLIA'
  }

  hdp-hadoop::package { 'hadoop':}
 
  hdp::user{ $hdfs_user:}
  hdp::user { $mapred_user:}

  hdp::directory { $conf_dir:}
  
  $logdirprefix = $hdp-hadoop::params::hadoop_logdirprefix
  hdp::directory_recursive_create { $logdirprefix: 
      owner => 'root'
  }
  $piddirprefix = $hdp-hadoop::params::hadoop_piddirprefix
  hdp::directory_recursive_create { $piddirprefix: 
      owner => 'root'
  }
 
  hdp-hadoop::configfile { ['hadoop-env.sh','core-site.xml','hdfs-site.xml','hadoop-policy.xml','taskcontroller.cfg','health_check']: 
    context_tag => common, 
    owner => $hdfs_user
  }

  hdp-hadoop::configfile { 'hadoop-metrics2.properties' : 
    context_tag  => common, 
    owner        => $hdfs_user,
    template_tag => $hadoop-metrics2_tag
  }

  hdp-hadoop::configfile { 'mapred-site.xml': 
    context_tag => common, 
    owner => $mapred_user
  }

  anchor{'hdp-hadoop::begin':} -> Hdp-hadoop::Package<||> ->  Hdp::User<|title == $hdfs_user or title == $mapred_user|> 
  -> Hdp::Directory[$conf_dir] -> Hdp-hadoop::Configfile<|context_tag == 'common'|> -> anchor{ 'hdp-hadoop::end':}
  Anchor['hdp-hadoop::begin'] -> Hdp::Directory_recursive_create[$logdirprefix] -> Anchor['hdp-hadoop::end']
  Anchor['hdp-hadoop::begin'] -> Hdp::Directory_recursive_create[$piddirprefix] -> Anchor['hdp-hadoop::end']
}

define hdp-hadoop::common()
{
}

###config file helper
define hdp-hadoop::configfile(
  $owner = undef,
  $hadoop_conf_dir = $hdp-hadoop::params::conf_dir,
  $mode = undef,
  $namenode_host = undef,
  $jtnode_host = undef,
  $snamenode_host = undef,
  $context_tag = undef,
  $template_tag = undef,
  $size = undef
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
    jtnode_host    => $calc_jtnode_host,
    size           => $size
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
