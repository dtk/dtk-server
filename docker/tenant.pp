$extlookup_datadir = '/etc/puppet/manifests/extdata'
$extlookup_precedence = ['common']
$dtk_assembly_node = "tenant"
stage{1:} -> stage{2:} -> stage{5:} -> stage{7:} -> stage{8:} -> stage{11:} -> stage{13:} -> stage{14:} -> stage{17:} -> stage{18:} -> stage{19:}
 
class {"stdlib": stage => 1}
 
class {"dtk": stage => 2}
 
#class {"dtk_java": stage => 3}
 
#class {"dtk_activemq": user => "mcollective", password => "marionette", subcollective => "mcollective", stage => 4}
 
class dtk_stage5 {
  common_user {"dtk1": user => "git1"}
}
class {"dtk_stage5": stage => 5}
 
#class dtk_stage6 {
#  gitolite {"dtk1": gitolite_user => "git1"}
#}
#class {"dtk_stage6": stage => 6}
 
class dtk_stage7 {
  dtk_server::ruby193install {"dtk1": install => "true"}
}
class {"dtk_stage7": stage => 7}
 
class {"dtk_server::base": stage => 8}
 
#class {"dtk_postgresql::server": stage => 9}
 
#class dtk_stage10 {
#  dtk_postgresql::db {"dtk1": db_name => "dtk1"}
#}
#class {"dtk_stage10": stage => 10}
 
class dtk_stage11 {
  dtk_server::tenant {"dtk1": 
  stomp_server_host => 'dario.dtk.io',
  local_repo_host   => 'dario.dtk.io',
  server_public_dns => 'dario.dtk.io',
  db_host => 'dario.dtk.io',


activemq_password => "marionette", activemq_subcollective => "mcollective", remote_repo_git_user => "git", update_hosts_file => "true", aws_access_key_id => "", aws_secret_access_key => "", remote_repo_port => "443", server_branch => "master", tenant_user => "dtk1", gitolite_user => "git1", remote_repo_host => "repoman1.internal.r8network.com"}
}
class {"dtk_stage11": stage => 11}
 
#class dtk_stage12 {
#  gitolite::admin_client {"dtk1": client_name => "dtk1", gitolite_user => "git1"}
#}
#class {"dtk_stage12": stage => 12}
 
class {"vcsrepo::include": stage => 13}
 
class dtk_stage14 {
  common_user::common_user_ssh_config {"dtk1": user => "dtk1"}
}
class {"dtk_stage14": stage => 14}
 
#class dtk_stage15 {
#  dtk_server::add_user {"dtk1": tenant_user_password => "r8server", tenant_user => "dtk1", tenant_db_user => "dtk1"}
#}
#class {"dtk_stage15": stage => 15}
 
#class dtk_stage16 {
#  dtk_server::cron_idle_instances {"dtk1": tenant_password => "r8server"}
#}
#class {"dtk_stage16": stage => 16}
 
class {"dtk_passenger": stage => 17}
 
class {"dtk_nginx::base": stage => 18}
 
class dtk_stage19 {
  dtk_nginx::vhost_for_tenant {"dtk1": instance_name => "dtk1"}
}
class {"dtk_stage19": stage => 19}
