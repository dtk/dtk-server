$extlookup_datadir = '/etc/puppet/manifests/extdata'
$extlookup_precedence = ['common']
$dtk_assembly_node = "tenant"
stage{1:} -> stage{2:}
 
class {"dtk_postgresql::server":  max_connections => '50', ssl => 'off', stage => 1}
 
class dtk_stage2 {
  dtk_postgresql::db {"dtk1": db_name => "dtk1"}
}
class {"dtk_stage2": stage => 2}
