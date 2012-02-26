define hdp::package(
  $ensure = present,
  $size = undef,
  $included = false
  )
{
  #does not support changing size once this has been run
  
  $package_type = $name

  include hdp::params
  $repo_url = $hdp::params::repo_url
  $artifact_dir = $hdp::params::artifact_dir

  #compute size to use (calc_size)
  #1) if size given, use that
  #2) if 64 bit and 64 bit package is availble, use 64; 
  #3) otherwise use 32
  if ($size == undef) {
    #TODO: make sure have full set of possible model numbers
    if (undef != $hdp::params::package_file_names[$package_type][64]) and ($::hardwaremodel in [x86_64]) {
      $calc_size = 64
    } else {
      $calc_size = 32
    }
  } else {
    $calc_size = 32
  }
  $package_fn = $hdp::params::package_file_names[$package_type][$calc_size]
  if ($package_fn == undef) {
    hdp_fail("Cannot find package ${package_type} of size ${calc_size}")
  }
  
  $package_name = regsubst($package_fn,'^(.+)\.rpm$','\1')
  $package_url = "${repo_url}/${package_fn}"  
  $package_target = "${artifact_dir}/${package_fn}"
  
  include hdp::service::artifact_dir
 
  #TODO: hardcoded provider type; changing to allowing choice; default being yum or apt-get
  exec{ "wget ${package_fn}":
    command => "wget --tries=10 ${package_url} -O ${package_target}",
    creates => $package_target,
    
    path    => ["/usr/bin/"]
  }

  package{ $package_name:
    ensure   => $ensure,
    provider => rpm,
    source   =>  $package_target
  }
  Class['hdp::service::artifact_dir'] -> Exec["wget ${package_fn}"] -> Package[$package_name] 
}

class hdp::service::artifact_dir()
{
  file{ $hdp::params::artifact_dir:
    ensure  => directory
  }
}