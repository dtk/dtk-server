class hdp-hcat(
  $server = false
) 
{
 include hdp-hcat::params

  $hcat_user = $hdp-hcat::params::hcat_user
  $hcat_config_dir = $hdp-hcat::params::conf_dir
 
  hdp::package { 'hcat-base' : }
  if ($server == true ) {
    hdp::package { 'hcat-server':} 
  }
  hdp::user{ $hcat_user:}

  hdp::directory { $hcat_config_dir: }

# hdp-hcat::configfile { 'hcat-env.sh':}
# ... 
 
  anchor { 'hdp-hcat::begin': } -> Hdp::Package['hcat-base'] -> Hdp::User[$hcat_user] -> 
   Hdp::Directory[$hcat_config_dir] -> Hdp-hcat::Configfile<||> -> anchor { 'hdp-hcat::end': }

   if ($server == true ) {
     Hdp::Package['hcat-base'] -> Hdp::Package['hcat-server'] ->  Hdp::User[$hcat_user]
   }
}

### config files
define hdp-hcat::configfile(
  $mode = undef,
  $hcat_server_host = under
) 
{
  hdp::configfile { $name:
    component        => 'hcat',
    owner            => $hdp-hcat::params::hcat_user,
    conf_dir         => $hdp-hcat::params::conf_dir,
    mode             => $mode,
    hcat_server_host => $hcat_server_host 
  }
}
