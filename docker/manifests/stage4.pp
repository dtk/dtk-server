$extlookup_datadir = '/etc/puppet/manifests/extdata'
$extlookup_precedence = ['common']
$dtk_assembly_node = "tenant"
stage{1:} 
 
class {"dtk_passenger": stage => 1}
 
