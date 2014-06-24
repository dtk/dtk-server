require 'rubygems'
require 'faye'
# EM.run {
  bayeux = Faye::RackAdapter.new(:mount => '/faye', :timeout => 25)
  bayeux.listen(9292)
#}
