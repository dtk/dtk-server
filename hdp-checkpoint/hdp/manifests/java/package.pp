define hdp::java::package(
  $size,
  $include_artifact_dir = true
)
{
    
  include hdp::params
  
  $jdk_bin = $hdp::params::jdk_bins[$size]
  $artifact_dir = $hdp::params::artifact_dir
  $jdk_location = $hdp::params::jdk_location
  $jdk_wget_target = "${artifact_dir}/${jdk_bin}"
 
  
  if ($size == "32") {
    $java_home = $hdp::params::java32_home
  } else {
    $java_home = $hdp::params::java64_home
  }
  $java_exec = "${java_home}/bin/java"
  $java_dir = regsubst($java_home,'/[^/]+$','')
   
  if ($include_artifact_dir == true) {
    hdp::artifact_dir{ "java::package::${name}": }
  }
  
  $wget_cmd = "wget --tries=10 ${jdk_location}/${jdk_bin} -O ${jdk_wget_target}"
  exec{ "${wget_cmd} ${name}":
    command => $wget_cmd,
    creates => $jdk_wget_target,
    path    => ["/usr/bin/"],
    unless  => "test -e ${java_exec}"
  }
 
  $install_cmd = "mkdir -p ${java_dir} ; chmod +x ${jdk_wget_target}; cd ${java_dir} ; echo A | ${jdk_wget_target} -noregister > /dev/null 2>&1"
  exec{ "${install_cmd} ${name}":
    command => $install_cmd,
    unless  => "test -e ${java_exec}",
    path    => ["/bin","/usr/bin/"]
  }
  
  anchor{"hdp::java::package::${name}::begin":} -> Exec["${wget_cmd} ${name}"] ->  Exec["${install_cmd} ${name}"] -> anchor{"hdp::java::package::${name}::end":}
  if ($include_artifact_dir == true) {
    Anchor["hdp::java::package::${name}::begin"] -> Hdp::Artifact_dir["java::package::${name}"] -> Exec["${wget_cmd} ${name}"]
  }
}