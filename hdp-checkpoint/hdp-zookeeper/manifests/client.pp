class hdp-zookeeper::client()
{
  class { 'hdp-zookeeper' : type => 'client'}
}