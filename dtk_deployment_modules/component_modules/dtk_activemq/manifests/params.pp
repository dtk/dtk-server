class dtk_activemq::params(){
  $version = '5.8.0'
  $app_dir = "/opt/activemq"
  $mirror = 'http://dtk-storage.s3.amazonaws.com/activemq'
  $untarred_bin_tar_gz_dir = "apache-activemq-${version}"
  $bin_tar_gz_file = "${untarred_bin_tar_gz_dir}-bin.tar.gz"
  $bin_tar_gz_url = "${mirror}/${version}/${bin_tar_gz_file}"
}
