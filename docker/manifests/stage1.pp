$extlookup_datadir = '/etc/puppet/manifests/extdata'
$extlookup_precedence = ['common']
$dtk_assembly_node = "tenant"
stage{1:} -> stage{2:} -> stage{3:} -> stage{4:} -> stage{5:} #-> stage{6:}
 
class {"stdlib": stage => 1}
 
class {"dtk": stage => 2}
 
class {"dtk_java": stage => 3}
 
class {"dtk_activemq": user => "mcollective", password => "marionette", subcollective => "mcollective", stage => 4}
 
class dtk_stage5 {
  common_user {"dtk1": user => "git1"}
}
class {"dtk_stage5": stage => 5}
 
# class dtk_stage6 {
#   gitolite {"dtk1": gitolite_user => "git1"}
# }
# class {"dtk_stage6": stage => 6}