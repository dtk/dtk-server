r8_require('errors')
require 'grit'
require 'securerandom'
require 'active_support/hash_with_indifferent_access'


module DTK
  module PuppetForge

    #
    # Wrapper around puppet CLI (distributed via puppet gem)
    #
    class Error < Exception
    end

    class LocalCopy < Hash
      def initialize(output_hash,parent_install_dir,module_dependencies)
        super()
        merge!(output_hash).merge!('parent_install_dir' => parent_install_dir,'module_dependencies' => module_dependencies)
      end

      def self.random_install_dir()
        "/tmp/puppet/#{SecureRandom.uuid}"
      end
    end


    class Client
      class << self

        # user and name sepparator used by puppetforge
        MODULE_NAME_SEPARATOR = '-'


        def install(module_name, puppet_version=nil, force=false)
          raise DTK::Puppet::ModuleNameMissing, "Puppet forge module name not provided" if module_name.nil? || module_name.empty?

          # dir name
          dir_name         = module_name.split(MODULE_NAME_SEPARATOR, 2).last
          rand_install_dir = LocalCopy.random_install_dir()

          command  = "puppet _3.4.0_ module install #{module_name} --render-as json --target-dir #{rand_install_dir} --modulepath #{rand_install_dir}"
          command += " --version #{puppet_version}" if puppet_version && !puppet_version.empty?
          command += " --force"              if force

          output_s = `#{command}`

          # we remove invalid characters to get to JSON response
          output_s = normalize_output(output_s)
          output_hash   = JSON.parse(output_s)
          output_hash['install_dir'] += "/#{dir_name}"
          unless 'success'.eql?(output_hash['result'])
            raise ErrorUsage, "Puppet Forge Error: #{output_hash['error']['oneline']}"
          end
          module_dependencies = check_for_dependencies(module_name, output_hash)
          LocalCopy.new(output_hash,rand_install_dir,module_dependencies)
        end

        #
        # Verify if puppet forge module name is supported, to new name
        #

        def is_module_name_valid?(puppet_forge_name, module_name)
          pf_module_name = puppet_forge_name.split(MODULE_NAME_SEPARATOR, 2).last

          unless module_name
            raise ErrorUsage.new("Please provide module name")
          end

          unless module_name.eql?(pf_module_name)
            raise ErrorUsage.new("Install with module name (#{module_name}) unequal to puppet forge module name (#{pf_module_name}) is currently not supported.")
          end
        end

      private

        def check_for_dependencies(module_name, json)
          result = { :module_name => module_name, :dependencies => [] }

          if json['installed_modules'] && main_module = json['installed_modules'].first
            result[:dependencies] = main_module['dependencies'].collect do |dp|
              dp_name     = dp['module']
              dp_module_namespace, dp_module_name = extrace_namespace_and_name(dp_name)
              dp_version  = dp['version'] ? dp['version']['vstring'] : nil
              dp_full_id  = "#{dp_name}"
              dp_full_id += " (#{dp_version})" if dp_version
              ActiveSupport::HashWithIndifferentAccess.new({
                :name => dp_name, :module_name => dp_module_name,
                :module_namespace => dp_module_namespace, :version => dp_version,
                :full_id => dp_full_id, :module_type => 'component_module'
              })
            end
          end

          return result
        end

        def extrace_namespace_and_name(pf_module_name)
          pf_module_name.split(MODULE_NAME_SEPARATOR, 2)
        end

        def normalize_output(output_s)
          output_s = output_s.split("\e[0m\n").last
          output_s
        end

      end
    end

  end
end
=begin
TODO: deprecate or use in LoaclCopy


        #
        # We use installed puppet forge gem and initialize git repo in it, after which we push it to gitolite.
        #

        def push_to_server(project, local_params, pf_module_location, gitolite_remote_url, pf_parent_location)
          local = local_params.create_local(project) 
          branch_name = local.branch_name 
          repo = Grit::Repo.init(pf_module_location)

          # after init we add all and push to our tenant
          repo.remote_add('tenant_upstream', gitolite_remote_url)
          repo.git.pull({},'tenant_upstream')
          repo.git.checkout({:env => {'GIT_WORK_TREE' => pf_module_location} }, branch_name)
          repo.git.add({:env => {'GIT_WORK_TREE' => pf_module_location} },'.')
          repo.git.commit({:env => {'GIT_WORK_TREE' => pf_module_location} }, '-m','Initial Commit')
          repo.git.push({},'-f', 'tenant_upstream', branch_name)

          # get head commit sha
          head_commit_sha = repo.head.commit.id

          # we remove not needed folder after push
          FileUtils.rm_rf(pf_parent_location)

          head_commit_sha
        end
=end
