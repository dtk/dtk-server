class hdp-zookeeper::client()
{
  #TODO: move link to init
  $cmd = "ln -s /usr/libexec/zkEnv.sh /usr/bin/zkEnv.sh"
  $test = "test -e /usr/bin/zkEnv.sh"

  class { 'hdp-zookeeper' : type => 'client'} ->
  hdp::exec { $cmd :
     command => $cmd,
     unless  => $test
  }
}
