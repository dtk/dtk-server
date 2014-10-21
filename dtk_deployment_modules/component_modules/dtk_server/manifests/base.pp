class dtk_server::base() inherits dtk_server::params
{
  package { $app_packages:
    ensure => 'installed',
  }

  create_resources(package, $non_bundler_gems)

  package { 'bundler':
    ensure   => 'installed',
    provider => 'gem'
  }

  file { $config_base:
    ensure   => 'directory',
  }

  exec { 'mcollective-conn-plugin-dir':
    command => "/bin/mkdir -p ${mcollective_plugins_dir}/mcollective/connector",
    creates => "${mcollective_plugins_dir}/mcollective/connector",
  }

  exec { 'mcollective-security-plugin-dir':
    command => "/bin/mkdir -p ${mcollective_plugins_dir}/mcollective/security",
    creates => "${mcollective_plugins_dir}/mcollective/security",
  }

  file { "${mcollective_plugins_dir}/mcollective/connector/stomp_em.rb" :
    ensure => 'present',
    source => 'puppet:///modules/dtk_server/mcollective/connector/stomp_em.rb',
    require => Exec['mcollective-conn-plugin-dir']
  }   
  
  file { "${mcollective_plugins_dir}/mcollective/security/sshkey.rb" :
    ensure => 'present',
    source => 'puppet:///modules/dtk_server/mcollective/security/sshkey.rb',
    require => Exec['mcollective-security-plugin-dir']
  }   
   
  file { "${mcollective_plugins_dir}/mcollective/security/sshkey.ddl" :
    ensure => 'present',
    source => 'puppet:///modules/dtk_server/mcollective/security/sshkey.ddl',
    require => Exec['mcollective-security-plugin-dir']
  }   
 
  dtk_server::git_repo_keyscan { $repo_hostnames: } 

  include dtk_server::base::sudo_includedir
}

class dtk_server::base::sudo_includedir() inherits dtk_server::params
{
  $sudo_base_cmd = "echo '#includedir ${sudo_config_dir}' >> ${sudo_config_file}"
  $sudo_cmd = "chmod 640 ${sudo_config_file}; ${sudo_base_cmd}; chmod 440 ${sudo_config_file}"
  $sudo_unless =  "grep '#includedir' ${sudo_config_file} | grep ${sudo_config_dir}"
  exec { 'update sudoers':
    command => $sudo_cmd,
    unless  => $sudo_unless,
    path    => ['/bin']
  }
}
