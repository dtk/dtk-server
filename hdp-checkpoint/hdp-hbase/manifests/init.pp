class hdp-hbase() 
{
  include hdp-hbase::params
 
  $hbase_user = $hdp-hbase::params::hbase_user
  $config_dir = $hdp-hbase::params::conf_dir
 
  hdp::package { 'hbase': }
  
  hdp::user{ $hbase_user:}
 
  hdp::directory { $config_dir: }

  hdp-hbase::configfile { 'hbase-env.sh': }
  hdp-hbase::configfile { 'hbase-site.xml': } 

  #top level does not need anchors
  Hdp::Package<|title == 'hadoop' and included == 'false'|> -> Hdp::Package['hbase'] -> Hdp::User[$hbase_user] -> Hdp::Directory[$config_dir] -> 
   Hdp-hbase::Configfile<||>  
}

#using define vs class because cannot uses class in collect statement
#$namenode is used for conditional ordering in componet role classes
#only realized under 1 name
define hdp-hbase::common($master = false)
{
  include hdp-hbase
  anchor{'hdp-hbase::common::begin' :} -> Class['hdp-hbase'] -> anchor{'hdp-hbase::common::end' :}
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
