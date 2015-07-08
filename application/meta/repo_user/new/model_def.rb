{
  schema: :repo,
  table: :user,
  columns: {
    username: {type: :varchar, size: 50},
    index: {type: :integer, default: 1}, #TODO: to prevent obscure race condition may make this a sequence
    type: {type: :varchar, size: 20}, #system | node | client
    component_module_direct_access: {type: :boolean, default: false},
    service_module_direct_access: {type: :boolean, default: false},
    repo_manager_direct_access: {type: :boolean, default: false},
    ssh_rsa_pub_key: {type: :text},
    ssh_rsa_private_key: {type: :text} #used when handing out keys to node types; #TODO: may encrypt in db
  }
}
