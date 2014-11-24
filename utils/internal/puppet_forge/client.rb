r8_require('errors')
require 'grit'

module DTK
  module PuppetForge

    #
    # Wrapper around puppet CLI (distributed via puppet gem)
    #

    class Client
      class << self

        # user and name sepparator used by puppetforge
        MODULE_NAME_SEPARATOR = '-'


        def install(module_name, version=nil, force=false)
          raise DTK::Puppet::ModuleNameMissing, "Puppet forge module name not provided" if module_name.nil? || module_name.empty?

          # dir name
          dir_name = module_name.split(MODULE_NAME_SEPARATOR, 2).last

          command = "puppet module install #{module_name} --render-as json"
          command+= " --version #{version}" if version
          command+= " --force"              if force

          output_s = `#{command}`

          # we remove invalid characters to get to JSON response
          output_s = output_s.split("\e[0m\n").last
          output   = JSON.parse(output_s)

          # augment data with install_dir info
          output['install_dir'] += "/#{dir_name}"

          output
        end

        #
        # We use installed puppet forge gem and initialize git repo in it, after which we push it to gitolite.
        #

        def push_to_server(pf_module_location, gitolite_remote_url)
          repo = Grit::Repo.init(pf_module_location)

          # after init we add all and push to our tenant
          repo.remote_add('tenant_upstream', gitolite_remote_url)
          repo.git.add({:env => {'GIT_WORK_TREE' => pf_module_location} },'.')
          repo.git.commit({:env => {'GIT_WORK_TREE' => pf_module_location} }, '-m','Initial Commit')
          repo.git.push({},'tenant_upstream','master')

          # get head commit sha
          head_commit_sha = repo.head.commit.id

          # we remove not needed folder after push
          FileUtils.rm_rf(pf_module_location)

          head_commit_sha
        end

      end
    end

  end
end