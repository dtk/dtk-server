#Call this definition only in case of installing 1.9 ruby version (nodes have 1.8.7 installed by default)
include dtk_server::params

define dtk_server::ruby193install($install)
{
  include rvm
  $ruby_version = $dtk_server::params::ruby_version

  if $::osfamily == 'Debian' {
    exec { 'apt-get-update':
     command => '/usr/bin/apt-get update && /usr/bin/touch /tmp/apt-get-update-run',
     before  => [ Rvm_system_ruby[$ruby_version], Class['rvm::dependencies::ubuntu'] ],
     creates => '/tmp/apt-get-update-run'
    }
  }

  # Temporary fix (GPG signature verification failed) for rvm initial installation
  exec { 'gpg_signature_key':
    path    => "/usr/local/bin/:/bin/:/usr/bin/",
    command => "gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3",
    creates => "/root/.gnupg/trustdb.gpg"
  }

  rvm_system_ruby {
    $ruby_version:
    ensure      => 'present',
    default_use => true,
    # looks like 1.9.3 binaries are no longer available
    # or mybe not
    build_opts  => ['--binary'],
    require     => Exec['gpg_signature_key']
  }

  rvm_gem {
    'thin':
      name         => 'thin',
      ruby_version => $ruby_version,
      ensure       => latest,
      require      => Rvm_system_ruby[$ruby_version];
  }

}

define dtk_server::rvm_wrapper($creates) {
  exec { 'generate-wrapper':
    command => '/usr/local/rvm/bin/rvm wrapper default',
    creates => $creates,
  }
}


