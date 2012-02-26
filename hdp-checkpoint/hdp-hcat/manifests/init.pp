class hdp-zookeeper(
  $service_state = running,
) 
{
 include hdp-hcat::params

 $hcat_user = $hdp-hcat::params::hcat_user
 $hcat_config_dir = $hdp-hcat::params::conf_dir
 
 hdp::package { 'hcat-server':}
 
 hdp::user{ $hcat_user:}

 hdp::directory { $hcat_config_dir: }

# hdp-hcat::configfile { 'hcat-env.sh':}
# ... 
 
 class { 'hdp-hcat::service' : enable => $service_state}

 #top level does not need anchors
 Hdp::Package['hcat'] -> Hdp::User[$hcat_user] -> Hdp::Directory[$hcat_config_dir] -> Hdp-hcat::Configfile<||> -> Class['hdp-hcat::service']
}

### config files
define hdp-hcat::configfile(
  $mode = undef
) 
{
  hdp::configfile { $name:
    component       => 'hcat',
    owner           => $hdp-hcat::params::hcat_user,
    conf_dir        => $hdp-hcat::params::conf_dir,
    mode            => $mode
  }
}
