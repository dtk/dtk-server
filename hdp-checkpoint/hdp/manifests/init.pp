class hdp()
{
  include hdp::params
  
  group { $hdp::params::hadoop_user_group :
    ensure => present
  }
  
  hdp::user { $hdp::params::hadoop_user:}
  
  Group[$hdp::params::hadoop_user_group] -> Hdp::User[$hdp::params::hadoop_user]
  
  #TODO: stub for testing; can be replaced by logic that opens up just needed ports
  class{ 'hdp::iptables': ensure => stopped}
}

define hdp::user(
  $gid = $hdp::params::hadoop_user_group,
  $just_validate = false #if set to true wil not add user and wil fail if user is not there #TODO: implement
)
{
  user { $name:
    ensure     => present,
    managehome => true,
    gid        => $gid
  }
}

define hdp::file(
    $owner = $hdp::params::hadoop_user,
    $mode = undef,
    $content,
    $ensure = present,
    $group = $hdp::params::hadoop_user_group
) 
{
  file { $name :
    ensure  => $ensure,
    owner   => $owner,
    group   => $group,
    content => $content
  }
}
     
define hdp::directory(
  $owner = $hdp::params::hadoop_user,
  $group = $hdp::params::hadoop_user_group
  )
{
  file { $name :
    ensure    => directory,
    owner     => $owner,
    group     => $group,
    recurse   => $recurse
  }
}
define hdp::directory_recursive_create(
  $owner = $hdp::params::hadoop_user,
  $group = $hdp::params::hadoop_user_group,
  $context_tag = undef
  )
{
  hdp::exec {"mkdir -p ${name}" :
    command => "mkdir -p ${name}",
    creates => $name
  }
  #to take care of setting ownership
  hdp::directory { $name :
    owner => $owner,
    group => $group
  }
  Hdp::Exec["mkdir -p ${name}"] -> Hdp::Directory[$name]
}

### helper to do exec
define hdp::exec(
  $command,
  $refreshonly = undef,
  $unless = undef,
  $path = $hdp::params::exec_path,
  $user = undef,
  $creates = undef,
  $initial_wait = undef
)
{
     
  if ($initial_wait != undef) {
    hdp::wait { "service ${name}" : wait_time => $initial_wait}
  }
  
  exec { $name :
    command     => $command,
    refreshonly => $refreshonly,
    path        => $path,
    user        => $user,
    creates     => $creates,
    unless      => $unless
  }
  
  anchor{ "hdp::exec::${name}::begin":} -> Exec[$name] -> anchor{ "hdp::exec::${name}::end":} 
  if ($initial_wait != undef) {
    Anchor["hdp::exec::${name}::begin"] -> Hdp::Wait["service ${name}"] -> Exec[$name]
  }
}

#### utilities for waits
define hdp::wait($wait_time)
{
  exec { "wait ${name} ${wait_time}" :
    command => "/bin/sleep ${wait_time}"
  } 
}

##### temp

class hdp::iptables($ensure)
{
  #TODO: just temp so not considering things like saving firewall rules
  service { 'iptables':
    ensure => $ensure
  }
}
