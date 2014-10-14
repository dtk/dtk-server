#TODO: want internal links to connect these with gitolite params
class dtk_repo_manager::params()
{
  $gitolite_user = 'git'
  $admin_user = 'git'
  $gitolite_user_homedir = "/home/${gitolite_user}"
  $rsa_identity_dir = "${gitolite_user_homedir}/rsa_identity_dir"
  $utilities_base = "${gitolite_user_homedir}/repo_manager/utilities"

  $repoman_repo = 'repo_manager'
  $repoman_admin_repo = 'admin'
  $dtk_common_repo = 'common'
  $dtk_common_core_repo = 'common-core'

  #$app_repos = ['repo_manager','common', 'common-core','admin']
  $repo_info = {
    'repo_manager' => {
      repo_url   => 'git@github.com:rich-reactor8/dtk-repo-manager.git',
      target_dir => 'repo_manager',
      branch     => 'master'
    },
    'common' => {
      repo_url   => 'git@github.com:rich-reactor8/dtk-common.git',
      target_dir => 'common',
      branch   => 'master'
    },
    'common-core' => {
      repo_url   => 'git@github.com:rich-reactor8/dtk-common-repo.git',
      target_dir => 'dtk-common-core',
      branch   => 'master'
    },
    'admin' => {
      repo_url   => 'git@github.com:rich-reactor8/dtk-repoman-admin.git',
      target_dir => 'dtk-repoman-admin',
      branch   => 'master'
    }
  }

}
