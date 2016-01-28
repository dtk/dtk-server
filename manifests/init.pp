class dtk_activemq(
  $tenant_name    = 'dtk1',
  $user           = 'UNSET',
  $password       = 'marionette',
  $arbiter_topic  = "UNSET",
  $arbiter_queue  = "UNSET"
  ) {
  include dtk_activemq::params
  $app_dir = $dtk_activemq::params::app_dir

  if $arbiter_topic == 'UNSET' {
    $arbiter_topic_final = "arbiter.${tenant_name}.broadcast"
  }
  else {
    $arbiter_topic_final = $arbiter_topic
  }

  if $arbiter_queue == 'UNSET' {
    $arbiter_queue_final = "arbiter.${tenant_name}.reply"
  }
  else {
    $arbiter_queue_final = $arbiter_queue
  }
  
  if $user == 'UNSET' {
    $user_final = $tenant_name
  }
  else {
    $user_final = $user
  }

  class { 'dtk_activemq::package': }

  file { '/etc/default/activemq':
    source  => 'puppet:///modules/dtk_activemq/etc_activemq',
    mode    => '0600',
    require => Class['dtk_activemq::package']
  }

  file { '/opt/activemq/bin/activemq':
    source  => 'puppet:///modules/dtk_activemq/etc_initd_activemq',
    mode    => '770',
    require => Class['dtk_activemq::package']
  }

  file { '/etc/init.d/activemq':
   ensure  => 'link',
   target  => '/opt/activemq/bin/activemq',
   require => File['/opt/activemq/bin/activemq'],
  }

  file { "${app_dir}/conf/activemq.xml":
    content => template('dtk_activemq/activemq.xml.erb'),
    require => Class['dtk_activemq::package']
  }

  service { 'activemq':
    enable    => true,
    ensure    => true,
   #TODO: see why this is causing problem subscribe => File["${app_dir}/conf/activemq.xml"],
    require   => File['/etc/default/activemq','/etc/init.d/activemq',"${app_dir}/conf/activemq.xml"]
  }
}

class dtk_activemq::package() {

  include dtk_activemq::params
  $bin_tar_gz_file = $dtk_activemq::params::bin_tar_gz_file
  $bin_tar_gz_url =  $dtk_activemq::params::bin_tar_gz_url 
  $untarred_bin_tar_gz_dir = $dtk_activemq::params::untarred_bin_tar_gz_dir
  $app_dir = $dtk_activemq::params::app_dir  

  anchor { 'dtk_activemq::package::begin': }

  exec { 'wget activemq':
    command => "wget ${bin_tar_gz_url}",
    cwd     => "/tmp",
    creates => "/tmp/${bin_tar_gz_file}",
    path    => ['/usr/bin'],
    require => Anchor['dtk_activemq::package::begin']
  } 

  exec { 'untar activemq':
    command => "tar zxvf ${bin_tar_gz_file}; mv ${untarred_bin_tar_gz_dir} ${app_dir}",
    cwd     => "/tmp",
    creates => $app_dir,
    path    => ['/bin'],
    require => Exec['wget activemq'],
    before  => Anchor['dtk_activemq::package::end']
  } 

  anchor { 'dtk_activemq::package::end': }
}
