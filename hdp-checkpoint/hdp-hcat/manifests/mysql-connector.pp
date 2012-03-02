class hdp-hcat::mysql-connector()
{
  include hdp-hcat::params
  #TODO: assumes that artifact dir has been created; can rectify by eitehr using "include = true flag or 
  #by createing a wget fn in hdp included by hdp::package
  #fix when brining in yum

  $url = $hdp-hcat::params::mysql_connector_url
  $zip_name = $hdp-hcat::params::mysql_zip_name
  $jar_name = regsubst($zip_name,'zip$','-bin.jar')
  $target = "${hdp::params::artifact_dir}/${zip_name}"
  $hcat_lib = $hdp-hcat::params::hcat_lib
  
  exec{ "wget ${url}":
    command => "wget --tries=10 ${url} -O ${target}",
    creates => $target,
    path    => ["/usr/bin/"]
  }
  exec{ "unzip ${target}":
    command => "unzip -o -j ${target} '*.jar' -x */lib/*",
    cwd     => $hcat_lib,
    user    => $hdp::params::hcat_user,
    group   => $hdp::params::hadoop_user_group,
    creates => "${hcat_lib}/${$jar_name}",
    path    => ["/usr/bin/"]
  }

  Exec["wget ${url}"] -> Exec["unzip ${target}"]
}