define dtk_server::tenant(
  $stomp_server_host = $::ec2_public_hostname,
  $local_repo_host   = $::ec2_public_hostname,
  $server_public_dns = $::ec2_public_hostname,
  $db_host           = 'localhost',
  $server_git_branch = 'master',
  $port              = undef,
  $gitolite_user
) 
{
  include dtk_server::params
  $config_base = $dtk_server::params::config_base
  $app_repos = $dtk_server::params::app_repos
  if ($port == undef) {
    $port_val = $dtk_server::params::default_port
  } else {
    $port_val = $port
  }
  $app_user = $name
  $app_homedir = "/home/${app_user}"
  $gitolite_admin_directory = "${app_homedir}/gitolite-admin/" 

  ### install apps and gems
  user { $app_user:
    home       => $app_homedir,
    shell      => '/bin/bash',
    managehome => true
  }

  dtk_server::github_repo { $app_repos:
    app_user         => $app_user,
    app_user_homedir => $app_homedir,
    branch           => $server_git_branch,
    require          => User[$app_user]
  }

  $server_gemfile_dir = "${app_homedir}/server" #TODO: get away from hard coding in 'server'
  dtk_server::bundler_gems_install { $server_gemfile_dir:
    require  => Dtk_server::Github_repo[$app_repos]
  }
  
  ### mcollective log file directory
  dtk::directory_recursive_create { "/var/log/mcollective/${app_user} ${name}":
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

  file { "${config_base}/${app_user}/nodes_info.json":
    owner   => $app_user,
    content => template('dtk_server/nodes_info.json.erb'),
    require => File["${config_base}/${app_user}"]
  }
  
  dtk_server::tenant::schema_init{ $name:
    app_homedir => $app_homedir,
    require     => [File["${config_base}/${app_user}/server.conf"],Dtk_server::Bundler_gems_install[$server_gemfile_dir]]
  }

  dtk_server::tenant::add_sudo_access{ $name: }

}

define dtk_server::tenant::schema_init(
  $app_homedir
)
{   
  $db = $name
  $user = $name
  
  dtk_server::tenant::schema_exec { "dbrebuild.rb ${name}" :
    db          => $db,
    user        => $user,
    app_homedir => $app_homedir,
    utility_cmd => 'dbrebuild.rb',
    sql_test    => "SELECT count(*)=0 FROM information_schema.tables where table_schema = 'top';",
  }
   dtk_server::tenant::schema_exec { "initialize.rb ${name}" :
    db          => $db,
    user        => $user,
    app_homedir => $app_homedir,
    utility_cmd => 'initialize.rb',
    sql_test    => "SELECT count(*)=0 FROM library.library;",
  }
   dtk_server::tenant::schema_exec { "add_user.rb ${name}" :
    db          => $db,
    user        => $user,
    app_homedir => $app_homedir,
    utility_cmd => "add_user.rb ${name}",
    sql_test    => "SELECT count(*)=0 FROM top.id_info where uri = '/datacenter/private-${name}'" 
  }
  anchor { "dtk_server::tenant::schema_init::${name}::begin":} -> Dtk_server::Tenant::Schema_exec["dbrebuild.rb ${name}"] ->
  Dtk_server::Tenant::Schema_exec["initialize.rb ${name}"] ->
  Dtk_server::Tenant::Schema_exec["add_user.rb ${name}"] ->
  anchor { "dtk_server::tenant::schema_init::${name}::end":}
}

define dtk_server::tenant::schema_exec(
  $db,
  $user,
  $app_homedir,
  $utility_cmd,
  $sql_test
)
{
  $check = inline_template('psql <%=db %> --tuples-only -U postgres --command "<%= sql_test %>" | grep t') 
  exec { "${app_homedir}/server/application/utility/${utility_cmd}":
    cwd       => "${app_homedir}/server/application",
    logoutput => true,
    user      => $user,
    environment => ["USER=${user}"], #without this in Ruby ENV["USER"] = "ROOT"
    onlyif    => $check,
    path      => ['/bin','/usr/bin']
  }
}

define dtk_server::tenant::add_sudo_access()
{
  include dtk_server::params
  $username = $name
  file { "${dtk_server::params::sudo_config_dir}/${username}":
    ensure  => 'present',
    content => "${username}  ALL=(ALL) NOPASSWD:ALL",
    mode    => '0440'
  }
}