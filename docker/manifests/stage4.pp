$extlookup_datadir = '/etc/puppet/manifests/extdata'
$extlookup_precedence = ['common']
$dtk_assembly_node = "tenant"
stage{1:} -> stage{2:} -> stage{3:}
 
class {"dtk_passenger": stage => 1}
 
class {"dtk_nginx::base": stage => 2}
 
class dtk_stage3 {
  dtk_nginx::vhost_for_tenant {"dtk1": instance_name => "dtk1", tenant_type => 'http'}
}
class {"dtk_stage3": stage => 3}
