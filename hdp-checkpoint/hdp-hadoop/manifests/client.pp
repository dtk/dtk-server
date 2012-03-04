class hdp-hadoop::client()
{
  #assumption that if this on on node, no other hadoop roles will be on node
  class { 'hdp-hadoop': } #adds package, users, directories, and common configs
  Hdp-hadoop::Package<||>{include_64_bit => true}
}
