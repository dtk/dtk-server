class hdp-hbase() 
{
  include hdp-hbase::params
 
  $hbase_user = $hdp-hbase::params::hbase_user
  $config_dir = $hdp-hbase::params::conf_dir
 
  class { 'hdp-hbase::package': }
  
  hdp::user{ $hbase_user:}
 
  hdp::directory { $config_dir: }

  hdp-hbase::configfile { 'hbase-env.sh': }
  hdp-hbase::configfile { 'hbase-site.xml': } 

  #top level does not need anchors
  Hdp::Package<|title == 'hadoop' and included == 'false'|> -> Class['hdp-hbase::package'] -> Hdp::User[$hbase_user] -> Hdp::Directory[$config_dir] -> 
   Hdp-hbase::Configfile<||>  
}

#using define vs class because cannot uses class in collect statement
#$namenode is used for conditional ordering in componet role classes
#only realized under 1 name
define hdp-hbase::common($master = false)
{
  $hdp::params::component_exists['hdp-hbase'] = true
  include hdp-hbase
  anchor{'hdp-hbase::common::begin' :} -> Class['hdp-hbase'] -> anchor{'hdp-hbase::common::end' :}
}

### package 
class hdp-hbase::package()
{
  hdp::package { 'hbase': }
}

class hdp-hbase::sav-epackage()
{
  hdp::package { 'hbase': }
  
  hdp::exec { "Use jar from hadoop" :
    command => "rm -rf /usr/share/hbase/lib/hadoop-core-*.jar; ln -sf /usr/share/hadoop/hadoop-core-*.jar /usr/share/hbase/lib/.",
    subscribe   => Hdp::Package['hbase'],
    refreshonly => true
  }
  
  hdp::exec { "For hbase shell permissions" :
    command => "chmod o=+rwx /usr/share/hbase/",
    subscribe   => Hdp::Package['hbase'],
    refreshonly => true
  }
  anchor { 'hdp-hbase::package::begin': } -> Hdp::Package['hbase'] ->
  Hdp::Exec<|title == "Use jar from hadoop" or title == "For hbase shell permissions"|> -> anchor { 'hdp-hbase::package::end': }
}

### config files
define hdp-hbase::configfile(
  $mode = undef,
  $hbase_master_host = undef
) 
{
  hdp::configfile { $name:
    component         => 'hbase',
    owner             => $hdp-hbase::params::hbase_user,
    conf_dir          => $hdp-hbase::params::conf_dir,
    mode              => $mode,
    hbase_master_host => $hbase_master_host
  }
}
