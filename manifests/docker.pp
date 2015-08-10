class dtk_server::docker(
  $tenant_user,
  $tenant_internal      = 'dtk1',
  $tenant_password      = 'r8server',
  $stomp_server_host    = $::ec2_public_hostname,
  $local_repo_host      = $::ec2_public_hostname,
  $server_public_dns    = $::ec2_public_hostname,
  $gitolite_host        = $::ec2_public_hostname,
  $remote_repo_host,
  $remote_repo_port     = '443',
  $remote_repo_git_user = 'git',
  $remote_repo_username = undef,
  $remote_repo_pass     = undef,
  $db_host              = '/var/run/postgresql',
  $db_name              = $tenant_user,
  $tenant_user_pub_key  = undef,
  $activemq_user        = 'mcollective',
  $activemq_password    = 'marionette',
  $activemq_subcollective = 'mcollective',
  $activemq_use_hiera   = false,
  $aws_access_key_id,
  $aws_secret_access_key,
  $ec2_name_tag_format  = '${tenant}:${target}:${user}:${assembly}:${node}',
  $ec2_keypair          = 'testing_use1',
  $auth_to_repoman      = false,
  $port                 = undef,
  $docker_image,
  $docker_email         = undef,
  $docker_password_hash = undef,
  )
{

  include dtk_server::docker::params
  include 'nginx'
  
  $tenant_directory="${dtk_server::docker::params::volume_base}/${tenant_user}"
  $app_homedir = "/home/${tenant_internal}"
  $rsa_identity_dir_host = "${tenant_directory}/home/rsa_identity_dir_host"
  $rsa_identity_dir = "${app_homedir}/rsa_identity_dir"
  $gitolite_user="${tenant_user}-git"
  $gitolite_admin_directory = "${app_homedir}/gitolite-admin/"

  if $activemq_use_hiera == true {
    $activemq_hiera_conf = hiera(activemq)
    $activemq_user_final = $tenant_user
    $activemq_password_final = $activemq_hiera_conf["$activemq_user"]['password']
    $activemq_subcollective_final = $activemq_hiera_conf["$activemq_user"]['subcollective']
  }
  else {
    $activemq_user_final = $activemq_user
    $activemq_password_final = $activemq_password
    $activemq_subcollective_final = $activemq_subcollective
  }

  if ($port == undef) {
    $port_val = $dtk_server::params::default_port
  } else {
    $port_val = $port
  }
  
  $directory_list = [ $dtk_server::docker::params::volume_base,
                      $tenant_directory,
                      "${tenant_directory}/conf", 
                      "${tenant_directory}/home",
                      "${tenant_directory}/home/r8server-repo",
                      #$rsa_identity_dir_host,
                      "${tenant_directory}/logs",
                      "${tenant_directory}/logs/app",
                      "${tenant_directory}/logs/nginx",
                      "${tenant_directory}/socket",
                      "${tenant_directory}/.ssh",
                    ]

  $docker_volumes_list = [
                            "${tenant_directory}/conf/server.conf:/etc/dtk/dtk1/server.conf", 
                            "${tenant_directory}/home/r8server-repo:/home/dtk1/r8server-repo",
                            "${tenant_directory}/logs/app:/home/dtk1/server/current/application/log",
                            "${tenant_directory}/logs/nginx:/var/log/nginx",
                            "${tenant_directory}/socket:/var/run/nginx",
                            "${tenant_directory}/.ssh:/home/dtk1/.ssh",
                            "${tenant_directory}/.fog:/home/dtk1/.fog",
                            "${tenant_directory}/creds:/dtk-creds/creds",
                            "${tenant_directory}/home/gitolite-admin:/home/dtk1/gitolite-admin",
                            "/var/run/postgresql/:/var/run/postgresql/"
                          ]

  file { $directory_list:
    ensure => directory,
  }->

  user { $tenant_user: 
    ensure => present, 
    home => "${tenant_directory}/home", 
    managehome => true,
    #require => File[$directory_list],
  }->

  dtk_server::tenant::ssh_config { $tenant_user:
    tenant_user         => $tenant_user,
    rsa_identity_dir    => $rsa_identity_dir_host,
    app_user_homedir    => "${tenant_directory}/home",
    tenant_user_pub_key => undef,
    #require             => [File[$directory_list], User[$tenant_user]],
  }->

  exec { "${tenant_user} pub key":
    command => "ssh-keygen -q -t rsa -f ${tenant_directory}/.ssh/id_rsa -N '' ",
    #user    => $gitolite_user,
    creates => "${tenant_directory}/.ssh/id_rsa",
    path    => ['/usr/bin'],
    #require => File[$directory_list],
  }->

  file { "${tenant_directory}/conf/server.conf":
    content => template('dtk_server/server.conf.erb'),
    #require => File[$directory_list]
  }->

  class { 'dtk_server::docker::gitolite':
    tenant_user     => $tenant_user,
    tenant_internal => $tenant_internal,
    gitolite_host   => $gitolite_host,
    #require         => [Dtk_server::Tenant::Ssh_config[$tenant_user]]
  }->

  file { "${tenant_directory}/.ssh/config":
    ensure  => present,
    content => template('dtk_server/ssh/config.erb'),
  }->

  file { "${tenant_directory}/creds": 
    ensure  => present,
    content => template('dtk_server/docker/creds.erb'),
  }->

  file { "${tenant_directory}/.fog":
    ensure  => present,
    content => template('dtk_server/fog.erb'),
  }->

  docker::run { "dtk-${tenant_user}":
    image           => $docker_image,
    volumes         => $docker_volumes_list,
    #require        => Class['dtk_server::docker::gitolite'],
    pull_on_start   => true,
  }

  if $docker_email != undef {
    file { '/root/.dockercfg':
      ensure  => present,
      content => template('dtk_server/docker/dockercfg.erb'),
      before => Docker::Run["dtk-${tenant_user}"],
    }
  }

  dtk_nginx::vhost_for_tenant {$tenant_user:
    instance_name => $tenant_user,
    tenant_type   => 'docker',
    docker_socket => "${tenant_directory}/socket/nginx.sock",
  } 
}
