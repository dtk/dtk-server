$extlookup_datadir = '/etc/puppet/manifests/extdata'
$extlookup_precedence = ['common']
$dtk_assembly_node = "tenant"

class {"dtk_nginx::base": }->

dtk_nginx::vhost_for_tenant {"dtk1": instance_name => "dtk1", tenant_type => 'http'} 
