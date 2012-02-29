define hdp::package(
  $ensure = present,
  $size = undef,
  $included = false
  )
{
    
  $package_type = $name

  include hdp::params
  $repo_url = $hdp::params::repo_url
  $artifact_dir = $hdp::params::artifact_dir


  
  #does not support changing size once this has been run
  
  
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
  
  hdp::package::wget{ $package_fn:
    package_url    => $package_url,
    package_target => $package_target
  }
  
  package{ $package_name:
    ensure   => $ensure,
    provider => rpm,
    source   =>  $package_target
  }
 
  anchor{ "hdp::package::${name}::begin": } ->  hdp::artifact_dir{$name :} -> Hdp::Package::Wget[$package_fn] -> Package[$package_name] -> anchor{ "hdp::package::${name}::end": } 
  
}

define hdp::artifact_dir()
{
  include artifact_dir_shared
}

define hdp::save-artifact_dir()
{
  $artifact_dir = $hdp::params::artifact_dir
  exec { "mkdir ${artifact_dir} ${name}" :
    command => "mkdir ${artifact_dir}",
    creates => $artifact_dir,
    path    => ["/bin/"]
  }
}
class artifact_dir_shared()
{
  file{ $hdp::params::artifact_dir:
    ensure  => directory
  }
}
   

define hdp::package::wget(
  $package_url,
  $package_target
) {
 exec{ "wget ${name}":
    command => "wget --tries=10 ${package_url} -O ${package_target}",
    creates => $package_target,
    path    => ["/usr/bin/"]
  }
}
