#Call this definition only in case of installing 1.9 ruby version (nodes have 1.8.7 installed by default)
#include dtk_server::params

define dtk_server::ruby193install(
  $ruby_version = 'ruby-1.9.3-p484',
  $install)
{
  class { 'rvm': 
    install_dependencies => true,
  }
#  $ruby_version = $dtk_server::params::ruby_version

  if $::osfamily == 'Debian' {
    exec { 'apt-get-update':
     command => '/usr/bin/apt-get update && /usr/bin/touch /tmp/apt-get-update-run',
     before  => [ Rvm_system_ruby[$ruby_version], Class['rvm'], Package['git-core'] ],
     creates => '/tmp/apt-get-update-run'
    }
  }

  rvm_system_ruby {
    $ruby_version:
    ensure      => 'present',
    default_use => true,
    require     => Class['rvm'],
    # looks like 1.9.3 binaries are no longer available
    # or mybe not
    build_opts  => ['--binary'],
  }
}

define dtk_server::rvm_wrapper($creates) {
  exec { 'generate-wrapper':
    command => '/usr/local/rvm/bin/rvm wrapper default',
    creates => $creates,
  }
}


