class hdp-hcat::client(
  $hcat_server_host = undef
)
{   
  include hdp-hcat #installs package, creates user, sets configuration
  if ($hcat_server_host != undef) {
    Hdp-Hcat::Configfile<||>{hcat_server_host => $hcat_server_host}
  }
}

