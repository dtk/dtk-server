class hdp-zookeeper::quorum-member(
  $zookeeper_peers = []
) 
{
  include hdp::params
  #TODO: stub need to add in self
  $zookeeper_hosts = $zookeeper_peers
  Hdp-Zookeeper::Configfile<||>{zookeper_hosts=> $zookeeper_hosts}
}