class dtk_addons::jenkins_swarm_client(
  $user,
  $fsroot = "/home/${user}/jenkins",
  $master,
  $mode = "exclusive",
  $name,
  $username,
  $password
)
{
  $location = "/home/${user}"

  exec { 'download_swarm_agent':
    command => "wget http://maven.jenkins-ci.org/content/repositories/releases/org/jenkins-ci/plugins/swarm-client/1.10/swarm-client-1.10-jar-with-dependencies.jar",
    user    => $user,
    cwd     => $location,
    path    => [ "/usr/local/bin/", "/bin/", "/usr/bin/"],
  }

  file { "${fsroot}":
    ensure => "directory",
    owner  => $user,
    group  => $user,
    mode   => 775,
  }

  exec { 'run_swarm_agent':
    command => "nohup java -jar ${location}/swarm-client-1.10-jar-with-dependencies.jar -fsroot ${fsroot} -master ${master} -mode ${mode} -name ${name} -username ${username} -password ${password} &",
    user    => $user,
    path    => [ "/usr/local/bin/", "/bin/", "/usr/bin/"],
  }

  Exec['download_swarm_agent'] -> File["${fsroot}"] -> Exec['run_swarm_agent']
}

