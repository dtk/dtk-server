class dtk()
{
  case $operatingsystem {
    ubuntu: {
      class { 'dtk::ubuntu': }
    }
   }
}

class dtk::ubuntu()
{
  anchor { 'dtk::ubuntu::begin': }

  exec {'apt-get update dtk::ubuntu':
    command => 'apt-get update',
    path     => ['/usr/bin'],
    unless  => 'test -f /tmp/apt-get-update-run',
    require => Anchor['dtk::ubuntu::begin'],
    before  => Anchor['dtk::ubuntu::end']
  }

  exec {' touch for apt-get update dtk::ubuntu':
    command     => 'touch /tmp/apt-get-update-run',
    refreshonly => true,
    path     => ['/usr/bin'],
    subscribe   => Exec['apt-get update dtk::ubuntu'],
    require     => Anchor['dtk::ubuntu::begin'],
    before      => Anchor['dtk::ubuntu::end']
  }

  anchor { 'dtk::ubuntu::end': }
}

define dtk::directory_recursive_create(
  $path,    
  $owner = undef
)
{
  exec {"mkdir -p ${path} ${name}":
    command => "mkdir -p ${path}",
    creates => $path,
    path => ['/bin']
  }
  
  if $owner == undef {}
  else {
    exec {"mkdir-chown ${owner} ${path} ${name}" :
      command     => "chown ${owner} ${path}",
      path        => ['/bin'],
      refreshonly => true,
      subscribe   => Exec["mkdir -p ${path} ${name}"]
    }
  } 
}
 