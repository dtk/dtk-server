$extlookup_datadir = '/etc/puppet/manifests/extdata'
$extlookup_precedence = ['common']
$dtk_assembly_node = "tenant"
stage{1:} -> stage{2:} -> stage{3:} -> stage{5:} -> stage{6:}
 
class dtk_stage1 {
  dtk_server::ruby193install {"dtk1": install => "true"}
}
class {"dtk_stage1": stage => 1}
 
class {"dtk_server::base": stage => 2}
 
class dtk_stage3 {
  dtk_server::tenant {"dtk1": 
  update_hosts_file => "true", 
  server_branch => "master", 
  aws_access_key_id => "", 
  remote_repo_port => "443", 
  remote_repo_git_user => "git", 
  activemq_password => "marionette", 
  activemq_user => "dtk1",
  tenant_user => "dtk1", 
  gitolite_user => "git1", 
  aws_secret_access_key => "", 
  remote_repo_host => "",
  stomp_server_host => 'dtk1.dtk.io',
  local_repo_host   => 'dtk1.dtk.io',
  server_public_dns => 'dtk1.dtk.io',
  db_host => '/var/run/postgresql',
  clone_from_git => false,
  init_schema => false,
  bundler_deployment => false,
  seed_salts => false,
}
}
class {"dtk_stage3": stage => 3}
 
# class dtk_stage4 {
#   gitolite::admin_client {"dtk1": client_name => "dtk1", gitolite_user => "git1"}
# }
# class {"dtk_stage4": stage => 4}
 
class {"vcsrepo::include": stage => 5}
 
class dtk_stage6 {
  common_user::common_user_ssh_config {"dtk1": user => "dtk1"}
}
class {"dtk_stage6": stage => 6}
 

