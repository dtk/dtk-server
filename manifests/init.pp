class dtk_repo_manager(
  $rails_env = 'production',
  $repoman_dns_address = 'repoman1.dtk.io',
  $repoman_internal_dns_address = 'localhost',
  $repoman_port = '443',
  $admin_dns_address   = 'admin1.dtk.io',
  # can also be branch or commit sha
  $repoman_tag = 'master',
  $repoman_admin_tag = 'master',
  $dtk_common_tag = 'master',
  $dtk_common_core_tag = 'master',
  $smtp_username,
  $smtp_password,
  $smtp_hostname = 'email-smtp.us-east-1.amazonaws.com',
  $smtp_port = '587',
)
{
  include dtk_repo_manager::params
  class {'rvm':
    install_dependencies => true,
  }

  $gitolite_user = $dtk_repo_manager::params::gitolite_user
  $admin_user = $dtk_repo_manager::params::admin_user
  #$app_repos = $dtk_repo_manager::params::app_repos
  $utilities_base = $dtk_repo_manager::params::utilities_base
  $rvm_path = "/usr/local/rvm"
  $rvm_ruby_version = "ruby-1.9.3-p484"

  $gitolite_user_homedir = $dtk_repo_manager::params::gitolite_user_homedir

  #$repo = 'repo_manager'
  #$target = $dtk_repo_manager::params::repo_info[$repo]
  #$test_var =  $dtk_repo_manager::params::repo_info[admin][target_dir]
  $repo_target_dir = "${gitolite_user_homedir}/${dtk_repo_manager::params::repo_info[repo_manager][target_dir]}"
  $admin_target_dir = "${gitolite_user_homedir}/${dtk_repo_manager::params::repo_info[admin][target_dir]}"
  $repo_env_file="${repo_target_dir}/.env"
  $admin_env_file="${admin_target_dir}/.env"

  $bundle_install_command = "${rvm_path}/wrappers/default/bundle install --without development"
 
  package { 'libpq-dev': 
    ensure => 'installed'
  }

  package { 'nodejs':
    ensure => installed,
  }

  package { 'redis-server':
    ensure => installed,
  }

  service {'redis-server':
    ensure  => running,
    require => Package['redis-server'],
  }

  dtk_repo_manager::rvm { $rvm_ruby_version: }

  class { 'nginx::config':}

  class { "dtk_repo_manager::passenger":
     ruby_path => "${rvm_path}/wrappers/default/ruby",
     require   => Dtk_repo_manager::Rvm[$rvm_ruby_version],
  }

  #repoman vhost
  nginx::resource::vhost { $repoman_dns_address:
    www_root            => "${repo_target_dir}/public",
    index_files         => undef,
    ssl                 => true,
    ssl_cert            => "puppet:///modules/dtk_secret/dtk.io_combined.crt",
    ssl_key             => "puppet:///modules/dtk_secret/wildcard.dtk.io.key",
    ssl_dhparam         => "puppet:///modules/dtk_secret/dhparam.pem",
    ssl_protocols       => "TLSv1 TLSv1.1 TLSv1.2",
    ssl_ciphers         => "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK",
    ssl_stapling        => "on",
    ssl_stapling_verify => "on",
    ssl_cache           => "shared:SSL:50m",
    ssl_trusted_certificate    => "puppet:///modules/dtk_secret/dtk.io_combined.crt",
    rewrite_to_https    => true,
    add_header          => ["Strict-Transport-Security max-age=15768000"],
    vhost_cfg_append    => {
      'passenger_enabled'       => 'on',
      'rails_env'               =>  $rails_env,
      'server_name'             => "localhost ${::ec2_public_hostname}",
    },
    require => Class["dtk_repo_manager::passenger"],
  }

  #admin vhost
  nginx::resource::vhost { $admin_dns_address:
    www_root            => "${admin_target_dir}/public",
    index_files         => undef,
    ssl                 => true,
    ssl_cert            => "puppet:///modules/dtk_secret/dtk.io_combined.crt",
    ssl_key             => "puppet:///modules/dtk_secret/wildcard.dtk.io.key",
    ssl_dhparam         => "puppet:///modules/dtk_secret/dhparam.pem",
    ssl_protocols       => "TLSv1 TLSv1.1 TLSv1.2",
    ssl_ciphers         => "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK",
    ssl_stapling        => "on",
    ssl_stapling_verify => "on",
    ssl_cache           => "shared:SSL:50m",
    ssl_trusted_certificate    => "puppet:///modules/dtk_secret/dtk.io_combined.crt",
    rewrite_to_https    => true,
    add_header          => ["Strict-Transport-Security max-age=15768000"],
    vhost_cfg_append    => {
      'passenger_enabled' => 'on',
      'rails_env'         =>  $rails_env,
      #'passenger_env_var REPOMAN_HOST' => 'localhost',
      #'passenger_env_var REPOMAN_PORT' => '443',
    },
    require => Class["dtk_repo_manager::passenger"],
  }

  # put config in dotenv
  file { $repo_env_file:
    content => template("dtk_repo_manager/repoman_env.erb"),
    require => Dtk_repo_manager::Github_repo[$dtk_repo_manager::params::repoman_repo],
  }->
  
  exec { "bundle_install":
    command    => $bundle_install_command,
    cwd        => $repo_target_dir,
    logoutput  => true,
    timeout    => 600,
    require    => [ Dtk_repo_manager::Github_repo[$dtk_repo_manager::params::repoman_repo], Dtk_repo_manager::Rvm[$rvm_ruby_version] ]
  }

  file { $admin_env_file:
    content => template("dtk_repo_manager/admin_env.erb"),
    require => Dtk_repo_manager::Github_repo[$dtk_repo_manager::params::repoman_admin_repo],
  }->

  exec { "bundle_install_admin":
    command    => $bundle_install_command,
    cwd        => $admin_target_dir,
    logoutput  => true,
    timeout    => 600,
    require    => [ Dtk_repo_manager::Github_repo[$dtk_repo_manager::params::repoman_admin_repo], Dtk_repo_manager::Rvm[$rvm_ruby_version], Package["nodejs"] ]
  }

  exec { "rake_assets_precompile_admin":
    environment => ["RAILS_ENV=${rails_env}", "REPOMAN_HOST=localhost", "REPOMAN_PORT=443"],
    command => "/usr/local/rvm/wrappers/default/rake assets:precompile",
    user    => $gitolite_user,
    cwd     => $admin_target_dir,
    require => Exec["bundle_install_admin"],
  }

  exec { "rake_db_create":
    command => "/usr/local/rvm/wrappers/default/rake db:create",
    user  => $gitolite_user,
    cwd     => $repo_target_dir,
    require => [Exec["bundle_install"], Package["nodejs"]],
  }

  # Needed package for fuzzy search on repoman admin
  package { "postgresql-contrib-8.4":
    ensure  => "installed",
    require => Exec["rake_db_create"]
  }

  exec { "run_postgresql_contrib_script":
    command => "psql -U postgres -d repoman -f /usr/share/postgresql/8.4/contrib/pg_trgm.sql",
    path    => "/usr/bin/",
    user    => postgres,
    require => Package["postgresql-contrib-8.4"]
  }

  exec { "rake_db_migrate":
    command => "/usr/local/rvm/wrappers/default/rake db:migrate",
    user    => $gitolite_user,
    cwd     => $repo_target_dir,
    require => Exec["run_postgresql_contrib_script"],
  }

  exec { "rake_db_seed":
    command => "/usr/local/rvm/wrappers/default/rake db:seed",
    user    => $gitolite_user,
    cwd     => $repo_target_dir,
    require => Exec["rake_db_migrate"],
  }

  exec { "rake_ci_create_user":
    command => "/usr/local/rvm/wrappers/default/rake ci:create_user['dtk16','fakedtk@dtk.io','password','test','test']",
    user    => $gitolite_user,
    cwd     => $repo_target_dir,
    require => Exec["rake_db_seed"],
  }

  file { "/etc/init.d/sidekiq":
    content => template("dtk_repo_manager/sidekiq.init.erb"),
    mode    => "o+x",
    require => Exec["rake_ci_create_user"],
  }

  service { "sidekiq":
    enable      => true,
    ensure      => running,
    #hasstatus   => true,
    hasrestart  => true,
    require     => [ File["/etc/init.d/sidekiq"], Service["redis-server"] ],
  }

  
  if ($gitolite_user != $admin_user) {
    class { 'dtk_repo_manager::sudo':}
  }

  class { 'dtk_repo_manager::rsa_identity_dir':
    require => Common_user[$gitolite_user]
  }

  dtk_repo_manager::github_repo { $dtk_repo_manager::params::repoman_repo:
    repo_branch => $repoman_tag,
    require => Class['dtk_repo_manager::rsa_identity_dir']
  }

  dtk_repo_manager::github_repo { $dtk_repo_manager::params::repoman_admin_repo:
    repo_branch => $repoman_admin_tag,
    require => Class['dtk_repo_manager::rsa_identity_dir']
  }

  dtk_repo_manager::github_repo { $dtk_repo_manager::params::dtk_common_repo:
    repo_branch => $dtk_common_tag,
    require => Class['dtk_repo_manager::rsa_identity_dir']
  }

  dtk_repo_manager::github_repo { $dtk_repo_manager::params::dtk_common_core_repo:
    repo_branch => $dtk_common_core_tag,
    require => Class['dtk_repo_manager::rsa_identity_dir']
  }

  # make sure logs are rotated
  logrotate::rule { 'dtk-repoman':
    path          => "${repo_target_dir}/log/*.log",
    rotate        => 8,
    rotate_every  => 'week',
    missingok     => true,
    compress      => true,
    delaycompress => true,
    ifempty       => false,
    copytruncate  => true,
  }

  logrotate::rule { 'dtk-repoman-admin':
    path          => "${admin_target_dir}/log/*.log",
    rotate        => 8,
    rotate_every  => 'week',
    missingok     => true,
    compress      => true,
    delaycompress => true,
    ifempty       => false,
    copytruncate  => true,
  }
}

define dtk_repo_manager::github_repo(
  $repo_branch,
)
{
  $repo = $name
  include dtk_repo_manager::params
  #TODO: may convert to using create-resource
  $repo_url = $dtk_repo_manager::params::repo_info[$repo][repo_url]
  $target = $dtk_repo_manager::params::repo_info[$repo][target_dir]
  $branch = $repo_branch
  $gitolite_user = $dtk_repo_manager::params::gitolite_user
  $gitolite_user_homedir = $dtk_repo_manager::params::gitolite_user_homedir
     
  $repo_target_dir = "${gitolite_user_homedir}/${target}"
  $rsa_identity_dir = $dtk_repo_manager::params::rsa_identity_dir

  vcsrepo { $repo_target_dir: 
    ensure   => 'present',
    owner    => $gitolite_user, 
    group    => $gitolite_user,
    user     => $gitolite_user,
    provider => 'git', 
    source   => $repo_url,
    revision => $branch,
    identity => "${rsa_identity_dir}/id_rsa"
  }
}

define dtk_repo_manager::rvm()
{
  $ruby_version = $name

  rvm_system_ruby {
    $ruby_version:
    ensure      => 'present',
    default_use => true,
    require     => Class['rvm'],
    # looks like 1.9.3 binaries are no longer available
    # or mybe not
    build_opts  => ['--binary'];
  }
}

class dtk_repo_manager::rsa_identity_dir()
{
  include dtk_repo_manager::params
  $gitolite_user = $dtk_repo_manager::params::gitolite_user
  $rsa_identity_dir = $dtk_repo_manager::params::rsa_identity_dir
  file { $rsa_identity_dir:
    ensure => 'directory'
  }   

  file { "${rsa_identity_dir}/id_rsa":
    ensure => 'present',
    mode   => '0600',
    owner  => $gitolite_user,
    source => 'puppet:///modules/dtk_repo_manager/ssh/id_rsa'
   }

   file { "${rsa_identity_dir}/id_rsa.pub":
     ensure => 'present',
     mode   => '0644',
     owner  => $gitolite_user,
     source => 'puppet:///modules/dtk_repo_manager/ssh/id_rsa.pub'
   }
}
