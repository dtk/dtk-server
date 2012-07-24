{
  :schema=>:repo,
  :table=>:user,
  :columns=>{
    :username => {:type=>:varchar, :size => 50},
    :index => {:type=>:integer, :default=>1}, #TODO: to prevent obscure race condition may make this a sequence
    :type => {:type=>:varchar, :size => 20}, #system | node | client
    :component_module_direct_access => {:type => :boolean, :default => false},
    :service_module_direct_access => {:type => :boolean, :default => false},
    :ssh_rsa_pub_key => {:type=>:text}
  }
}
