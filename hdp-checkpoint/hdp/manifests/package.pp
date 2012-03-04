define hdp::package(
  $ensure = present,
  $package_type = undef,
  $size = undef,
  $included = false,
  $provider = rpm
  )
{
 
  $pt = $package_type ? {
    undef  => $name,
    default  => $package_type
  }

  case $provider {
    'rpm':  { 
      hdp::package::wget-rpm { $name:
        ensure       => $ensure,
        package_type => $pt,
        size         => $size
      }
    }
    'yum': { 
      hdp::package::yum { $name:
        ensure       => $ensure,
        package_type => $pt,
        size         => $size
      }
    }
  }
}

######
define hdp::package::wget-rpm(
  $package_type,
  $ensure = present,
  $size = undef
  )
{
    
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
    $pn = $hdp::params::package_file_names[$package_type][64]
    if (("||" != "|${pn}|") and ($::hardwaremodel in [x86_64])) {
      $calc_size = 64
    } else {
      $calc_size = 32
    }
  } else {
    $calc_size = $size
  }
  $package_fn = $hdp::params::package_file_names[$package_type][$calc_size]
  if ($package_fn == undef) {
    hdp_fail("Cannot find package ${package_type} of size ${calc_size}")
  }
  
  $package_name = regsubst($package_fn,'^(.+)\.rpm','\1')
  $package_url = "${repo_url}/${package_fn}"  
  $package_target = "${artifact_dir}/${package_fn}"
  
  hdp::artifact_dir{$name :}
  
  hdp::java::package{ $name:
    size                 => $calc_size,
    include_artifact_dir => false
  }
  
  exec{ "wget ${name}":
    command => "wget --tries=10 ${package_url} -O ${package_target}",
    creates => $package_target,
    path    => ["/usr/bin/"]
  }
  
  package{ $package_name:
    ensure   => $ensure,
    provider => rpm,
    source   =>  $package_target
  }
 
  anchor{ "hdp::package::${name}::begin": } -> Hdp::Artifact_dir[$name] -> Hdp::Java::Package[$name] -> anchor{ "hdp::package::${name}::end": } 
  Hdp::Artifact_dir[$name] -> Exec["wget ${name}"] -> Package[$package_name] -> Anchor["hdp::package::${name}::end"] 
  
}
   
##TO: remove above after yum tested
##################### new yum based #################
define hdp::package::yum(
  $ensure = present,
  $package_type,
  $size = undef
  )
{
    
  include hdp::params
 
  #compute size to use (calc_size)
  #1) if size given, use that
  #2) if 64 bit and 64 bit package is availble, use 64; 
  #3) otherwise use 32
  if ($size == undef) {
    #TODO: make sure have full set of possible model numbers
    if (undef != $hdp::params::package_names[$package_type][64]) and ($::hardwaremodel in [x86_64]) {
      $calc_size = 64
    } else {
      $calc_size = 32
    }
  } else {
    $calc_size = 32
  }
  $package_name = $hdp::params::package_names[$package_type][$calc_size]
  if ($package_name == undef) {
    hdp_fail("Cannot find package ${package_type} of size ${calc_size}")
  }
  
  package{ $package_name:
    ensure   => $ensure,
    provider => yum,
  }
   #TODO: double check dp::package::yum::set_repo{$name :} -> Package[$package_name] to make sure can be many to one
  anchor{ "hdp::package::${name}::begin": } ->  hdp::package::yum::set_repo{$name :} -> Package[$package_name] -> anchor{ "hdp::package::${name}::end": } 
  
}

define hdp::package::yum::set_repo()
{
  $repo_info = '/etc/yum.repos.d/hdp.repo'
  exec{ "set yum repo for ${name}":
    command => "wget --tries=10 ${hdp::params::yum_repo} -O ${repo_info}",
    creates => $repo_info,
    path    => ["/usr/bin/"]
  }
}