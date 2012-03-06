class hdp()
{
  include hdp::params
  
  group { $hdp::params::hadoop_user_group :
    ensure => present
  }
  
  #TODO: think not needed and also there seems to be a puppet bug around this and ldap
  hdp::user { $hdp::params::hadoop_user:
    gid => $hdp::params::hadoop_user_group
  }
  Group[$hdp::params::hadoop_user_group] -> Hdp::User[$hdp::params::hadoop_user]

  hdp::package::common { 'common':}
  
  #TODO: add other package dependencies (see if apply also to yum) and move to params or package file
  Hdp::Package<|title == 'hadoop'|> ->   Hdp::Package<|title == 'hbase'|>

  #TODO: !!!!must remove stub for testing; 
  class{ 'hdp::iptables': ensure => stopped}
  exec { '/bin/echo 0 > /selinux/enforce':}
}

define hdp::user(
  $gid = $hdp::params::hadoop_user_group,
  $just_validate = undef
)
{
  $user_info = $hdp::params::user_info[$name]
  if ($just_validate != undef) {
    $just_val  = $just_validate
  } elsif ($user_info == undef) { 
    $just_val = false
  } else {
    $just_val = $user_info[just_validate]
  }
  
  if ($just_val == true) {
    exec { "user ${name} exists":
      command => "su - ${name} -c 'ls /dev/null' >/dev/null 2>&1",
      path    => ['/bin']
    }
  } else {
    user { $name:
      ensure     => present,
      managehome => true,
      gid        => $gid
    }
  }
}
     
define hdp::directory(
  $owner = $hdp::params::hadoop_user,
  $group = $hdp::params::hadoop_user_group,
  $mode  = undef
  )
{
  file { $name :
    ensure => directory,
    owner  => $owner,
    group  => $group,
    mode   => $mode
  }
}
#TODO: check on -R flag and use of recurse
define hdp::directory_recursive_create(
  $owner = $hdp::params::hadoop_user,
  $group = $hdp::params::hadoop_user_group,
  $mode = undef,
  $context_tag = undef
  )
{
  hdp::exec {"mkdir -p ${name}" :
    command => "mkdir -p ${name}",
    creates => $name
  }
  #to take care of setting ownership and mode
  hdp::directory { $name :
    owner => $owner,
    group => $group,
    mode  => $mode
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
    #passing in creates and unless so dont have to wait if condition has been acheived already
    hdp::wait { "service ${name}" : 
      wait_time => $initial_wait,
      creates   => $creates,
      unless    => $unless,
      path      => $path
    }
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
define hdp::wait(
  $wait_time,
  $creates = undef,
  $unless = undef,
  $path = undef #used for unless
)   
{
  exec { "wait ${name} ${wait_time}" :
    command => "/bin/sleep ${wait_time}",
    creates => $creates,
    unless  => $unless,
    path    => $path
  } 
}

#### artifact_dir
define hdp::artifact_dir()
{
  include artifact_dir_shared
}
class artifact_dir_shared()
{
  file{ $hdp::params::artifact_dir:
    ensure  => directory
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
