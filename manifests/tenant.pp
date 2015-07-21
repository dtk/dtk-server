define dtk_server::tenant(
  $update_hosts_file = 'true',
  $stomp_server_host = $::ec2_public_hostname,
  $local_repo_host   = $::ec2_public_hostname,
  $server_public_dns = $::ec2_public_hostname,
  $remote_repo_host,
  $remote_repo_port = '443',
  $remote_repo_git_user = 'git',
  $remote_repo_username = undef,
  $remote_repo_pass = undef,
  $db_host           = 'localhost',
  $server_branch = 'master',
  $port                 = undef,
  $gitolite_user,
  $tenant_user,
  $tenant_user_pub_key = undef,
  $activemq_user       = 'mcollective',
  $activemq_password   = 'marionette',
  $activemq_subcollective = 'mcollective',
  $activemq_use_hiera = false,
  $aws_access_key_id,
  $aws_secret_access_key,
  $ec2_name_tag_format = '${tenant}:${target}:${user}:${assembly}:${node}',
  $ec2_keypair = 'testing_use1',
  $auth_to_repoman = false,
) 
{ 
  include dtk_server::params
  $config_base = $dtk_server::params::config_base
  $server_repo = $dtk_server::params::server_repo
  $common_repo = $dtk_server::params::dtk_common_repo
  $common_core_repo = $dtk_server::params::dtk_common_core_repo

  $server_repo_pref = "${tenant_user}${server_repo}"
  $common_repo_pref = "${tenant_user}${common_repo}"
  $common_core_repo_pref = "${tenant_user}${common_core_repo}"

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

  # get the optional hostname argumetn
  include dtk_postgresql::params
  $hostname_argument = $dtk_postgresql::params::hostname_argument

  if ($port == undef) {
    $port_val = $dtk_server::params::default_port
  } else {
    $port_val = $port
  }
  $app_user = $tenant_user
  $app_homedir = "/home/${app_user}"
  $app_base = "${app_homedir}/server/current"
  $gitolite_admin_directory = "${app_homedir}/gitolite-admin/"

  ### install apps and gems
  user { $app_user:
    home       => $app_homedir,
    shell      => '/bin/bash',
    managehome => true
  }

  if $update_hosts_file == 'true' {  
   exec { "update_hosts-${tenant_user}":
     command => "/bin/echo \"127.0.0.1 ${tenant_user}.dtk.io\" >> /etc/hosts",
     unless  => "/bin/grep -c \"127.0.0.1 ${tenant_user}.dtk.io\" /etc/hosts",
   }  
  }
  
  #rsa_identity for github
  $rsa_identity_dir = "${app_homedir}/rsa_identity_dir"
  dtk_server::tenant::ssh_config { $app_user:
    tenant_user         => $app_user,
    rsa_identity_dir    => $rsa_identity_dir,
    app_user_homedir    => "/home/${app_user}",
    tenant_user_pub_key => $tenant_user_pub_key,
    require             => User[$app_user]
  }

  #git clone of DTK artifacts: server, common, common-core
  dtk_server::github_repo { $server_repo_pref:
    app_user         => $app_user,
    app_user_homedir => $app_homedir,
    branch           => $server_branch,
    identity         => "${rsa_identity_dir}/id_rsa",
    require          => Dtk_server::Tenant::Ssh_config[$app_user],
    notify           => Exec["passenger_restart_${name}"],
  }

  $passenger_restart_file = "${app_homedir}/server/current/application/tmp/restart.txt"
  exec { "passenger_restart_${name}":
    path => "/usr/sbin:/usr/bin:/sbin:/bin",
    command => "touch ${passenger_restart_file}",
  }

  $server_gemfile_dir = "${app_homedir}/server/current" #TODO: get away from hard coding in 'server'
  dtk_server::bundler_gems_install { $server_gemfile_dir:
    app_user => $app_user,
    require  => Dtk_server::Github_repo[$server_repo_pref]
  }

  # generate an rvm wrapper for thin (and other executable gems)
  # this is required to use an rvm gem in an init script
  dtk_server::rvm_wrapper { $app_user: 
    require => Dtk_server::Bundler_gems_install [ $server_gemfile_dir ],
    creates => '/usr/local/rvm/wrappers/default/thin'
  }

  ### mcollective log file directory
  dtk::directory_recursive_create { "/var/log/mcollective/${app_user} ${tenant_user}":
    path    => "/var/log/mcollective/${app_user}",
    owner   => $app_user,
    require => User[$app_user]
  }

  #### config file
  file { "${config_base}/${app_user}":
    ensure  => 'directory',
    owner   => $app_user,
    require => User[$app_user]
  }

  file { "${config_base}/${app_user}/server.conf":
    owner   => $app_user,
    content => template('dtk_server/server.conf.erb'),
    require => File["${config_base}/${app_user}"]
  }

  file  { "${config_base}/${app_user}/nodes_info.json":
    owner   => $app_user,
    source  => "${app_base}/nodes_info/public/nodes_info.json",
    require => [File["${config_base}/${app_user}"],Dtk_server::Github_repo[$server_repo_pref]]
  }

  #Place to add .fog file with aws credentials
  file { "/home/${app_user}/.fog":
    owner   => $app_user,
    content => template('dtk_server/fog.erb'),
    require => File["${config_base}/${app_user}"],
    mode   => 600,
  }

  dtk_server::tenant::schema_init{ $name:
    tenant_user => $tenant_user,
    app_homedir => $app_homedir,
    require     => [File["${config_base}/${app_user}/server.conf"],Dtk_server::Bundler_gems_install[$server_gemfile_dir]]
  }

  dtk_server::tenant::add_sudo_access{ $name: 
    tenant_user => $tenant_user,
  }  
}

define dtk_server::tenant::ssh_config(
  $tenant_user,
  $tenant_user_pub_key,
  $rsa_identity_dir,
  $app_user_homedir
)
{
  $app_user = $tenant_user
  $app_user_ssh_dir = "${app_user_homedir}/.ssh"
  Exec { path => '/bin:/usr/bin' }

  file { $rsa_identity_dir:
    ensure => 'directory',
    owner  => $app_user
  }

  file { "${rsa_identity_dir}/id_rsa":
    ensure => 'present',
    mode   => '0600',
    owner  => $app_user,
    source => 'puppet:///modules/dtk_server/ssh/id_rsa'
   }

   file { "${rsa_identity_dir}/id_rsa.pub":
     ensure => 'present',
     mode   => '0644',
     owner  => $app_user,
     source => 'puppet:///modules/dtk_server/ssh/id_rsa.pub'
   }

   # setup ssh keys for mcollective
   exec { "mcollective_local_key_${app_user}":
     command => "ssh-keygen -f ${rsa_identity_dir}/mcollective_local -P ''",
     user    => $app_user,
     creates => ["${rsa_identity_dir}/mcollective_local", "${rsa_identity_dir}/mcollective_local.pub"],
     require => File["$rsa_identity_dir"]
   }

   exec { "mcollective_remote_key_${app_user}":
     command => "ssh-keygen -f ${rsa_identity_dir}/mcollective_remote -P ''",
     user    => $app_user,
     creates => ["${rsa_identity_dir}/mcollective_remote", "${rsa_identity_dir}/mcollective_remote.pub"],
     require => File["$rsa_identity_dir"]
   }

   file { "${rsa_identity_dir}/authorized_keys":
     ensure  => 'present',
     mode    => '0600',
     owner   => $app_user,
     source  => "${rsa_identity_dir}/mcollective_remote.pub",
     require => Exec["mcollective_remote_key_${app_user}"]
   }

   # CA cert for logstash-forwarder
   file { "${rsa_identity_dir}/logstash-forwarder.crt":
     ensure  => 'present',
     mode    => '0600',
     owner   => $app_user,
     source  => 'puppet:///modules/dtk_server/logstash-forwarder.crt',
     require => File["$rsa_identity_dir"],
   }

   # add the pub key to the tenant user
   unless $tenant_user_pub_key == undef {
     dtk_user::simple_ssh_key { $app_user:
       rsa_pub_key => $tenant_user_pub_key,
       sudo_access => false
     }
   }
}

define dtk_server::tenant::schema_init(
  $tenant_user,
  $app_homedir
)
{
  $db = $tenant_user
  $user = $tenant_user

  dtk_server::tenant::schema_exec { "dbrebuild.rb ${tenant_user}" :
    db          => $db,
    user        => $user,
    app_homedir => $app_homedir,
    utility_cmd => 'dbrebuild.rb',
    sql_test    => "SELECT count(*)=0 FROM information_schema.tables where table_schema = 'top';",
  }
   dtk_server::tenant::schema_exec { "initialize.rb ${tenant_user}" :
    db          => $db,
    user        => $user,
    app_homedir => $app_homedir,
    utility_cmd => 'initialize.rb',
    sql_test    => "SELECT count(*)=0 FROM library.library;",
  }

  #Not possible to integrate with execution of other tenant functions - has dependency on gitolite-admin - moved to dtk_server::tenant::schema_adduser
  #if $tenant_user != "no_user" {
  #  dtk_server::tenant::schema_exec { "add_user.rb ${tenant_user}" :
  #    db          => $db,
  #    user        => $user,
  #    app_homedir => $app_homedir,
  #    utility_cmd => "add_user.rb ${tenant_user}",
  #    sql_test    => "unavaliable"
  #  }
  #  anchor { "dtk_server::tenant::schema_init::${name}::begin":} -> Dtk_server::Tenant::Schema_exec["dbrebuild.rb ${name}"] ->
  #  Dtk_server::Tenant::Schema_exec["initialize.rb ${name}"] ->
  #  Dtk_server::Tenant::Schema_exec["add_user.rb ${tenant_user}"] ->
  #  anchor { "dtk_server::tenant::schema_init::${name}::end":}
  #}
  #else {
  #  anchor { "dtk_server::tenant::schema_init::${name}::begin":} -> Dtk_server::Tenant::Schema_exec["dbrebuild.rb ${name}"] ->
  #  Dtk_server::Tenant::Schema_exec["initialize.rb ${name}"] ->
  #  anchor { "dtk_server::tenant::schema_init::${name}::end":}
  #}
  
  anchor { "dtk_server::tenant::schema_init::${tenant_user}::begin":} -> Dtk_server::Tenant::Schema_exec["dbrebuild.rb ${tenant_user}"] ->
    Dtk_server::Tenant::Schema_exec["initialize.rb ${tenant_user}"] ->
  anchor { "dtk_server::tenant::schema_init::${tenant_user}::end":}
}

define dtk_server::tenant::schema_exec(
  $db,
  $user,
  $app_homedir,
  $utility_cmd,
  $sql_test
)
{
  if $sql_test == "unavaliable" {
    exec { "/usr/local/rvm/wrappers/default/bundle exec ${app_homedir}/server/current/application/utility/${utility_cmd}":
      cwd       => "${app_homedir}/server/current/application",
      logoutput => true,
      user      => $user,
      environment => ["USER=${user}", "HOME=${app_homedir}"], #without this in Ruby ENV["USER"] = "ROOT"
      path      => ['/bin','/usr/bin', '/usr/local/bin/']
    }
  }
  else { 
    $check = inline_template('psql <%=db %> --tuples-only -U postgres ${hostname_argument} --command "<%= sql_test %>" | grep t')
    exec { "/usr/local/rvm/wrappers/default/bundle exec ${app_homedir}/server/current/application/utility/${utility_cmd}":
      cwd       => "${app_homedir}/server/current/application",
      logoutput => true,
      user      => $user,
      environment => ["USER=${user}", "HOME=${app_homedir}"], #without this in Ruby ENV["USER"] = "ROOT"
      onlyif    => $check,
      path      => ['/bin','/usr/bin', '/usr/local/bin/']
    }
  }
}

define dtk_server::tenant::add_sudo_access(
  $tenant_user
)
{
  include dtk_server::params
  $username = $tenant_user
  file { "${dtk_server::params::sudo_config_dir}/${username}":
    ensure  => 'present',
    content => "${username}  ALL=(ALL) NOPASSWD:ALL",
    mode    => '0440'
  }
}
