class dtk_client::resources(
  $user,  
)
{
  file {"/home/${user}/dtk/component_modules":
    ensure => directory,
    source => "puppet:///modules/dtk_client/component_modules",
    recurse => true,
    owner => "${user}",
    group => "${user}",
    mode => 0775,
  }

  file {"/home/${user}/dtk/service_modules":
    ensure => directory,
    source => "puppet:///modules/dtk_client/service_modules",
    recurse => true,
    owner => "${user}",
    group => "${user}",
    mode => 0775,
  }
}
