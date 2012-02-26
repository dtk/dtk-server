define hdp-hadoop::hdfs::directory(
  $owner = unset,
  $group = unset,
  $recursive_chown = false
) 
{
  $mkdir_cmd = "fs -mkdir ${name}"
  hdp-hadoop::exec-hadoop { $mkdir_cmd:
    command => $mkdir_cmd,
    unless => "hadoop fs -ls ${name} >/dev/null 2>&1"
  }
  if ($owner == unset) {
    $chown = ""
  } else {
    if ($group == unset) {
      $chown = $owner
    } else {
      $chown = "${owner}:${group}"
    } 
  }  
  if (chown != "") {
    #TODO: see if there is a good 'unless test'
    if ($recursive_chown == true) {
      $chown_cmd = "fs -chown -R ${chown} ${name}"
    else {
      $chown_cmd = "fs -chown ${chown} ${name}"
    }
    hdp-hadoop::exec-hadoop {$chown_cmd :
      command => $chown_cmd
    }
    Hdp-hadoop::Exec-hadoop[$mkdir_cmd] -> Hdp-hadoop::Exec-hadoop[$chown_cmd]
  }
}
