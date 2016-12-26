class cmd_test_case_5::component(
  $file_path,
) {
  file { $file_path:
    ensure => present,
    content => "Hello from file!",
    mode    => '0644',
  }
} 