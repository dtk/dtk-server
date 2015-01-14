require 'active_support/hash_with_indifferent_access'
require 'puppet'
require 'open3'

module DTK
  module PuppetForge
    #
    # Wrapper around puppet CLI (distributed via puppet gem)
    #
    class Client
      class << self

        def install(pf_module_name, puppet_version=nil, force=false)
          ret = nil
          base_install_dir = LocalCopy.random_install_dir()
          begin
            output_hash = execute_puppet_forge_call(pf_module_name,base_install_dir,puppet_version,force)
            unless 'success'.eql?(output_hash['result'])
              raise ErrorUsage, "Puppet Forge Error: #{output_hash['error']['oneline']}"
            end
            module_dependencies = check_for_dependencies(base_install_dir, pf_module_name, output_hash)
            ret = LocalCopy.new(output_hash, base_install_dir, module_dependencies)
           rescue Exception => e
            LocalCopy.delete_base_install_dir?(base_install_dir)
            raise e
          end
          ret
        end

      private

        # returns output_hash
        PUPPET_VERSION = '3.4.0'
        def execute_puppet_forge_call(pf_module_name,base_install_dir,puppet_version=nil, force=false)
          command  = "puppet _#{PUPPET_VERSION}_ module install #{pf_module_name} --render-as json --target-dir #{base_install_dir} --modulepath #{base_install_dir}"
          command += " --version #{puppet_version}" if puppet_version && !puppet_version.empty?
          command += " --force"              if force
          output_s = nil
          output_err = nil
          Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
            output_s = stdout.read
            output_err = stderr.read
          end
          raise_puppet_forge_error(output_err) unless output_err.empty?

          # we remove invalid characters to get to JSON response
          output_s = normalize_output(output_s)
          output_hash   = JSON.parse(output_s)
          output_hash['install_dir'] += "/#{PuppetForge.puppet_forge_module_name(pf_module_name)}"
          output_hash
        end

        def check_for_dependencies(base_install_dir, module_name, hash_info)
          if dependencies = ((hash_info['installed_modules']||{}).first||{})['dependencies']
            nested_dependency_info = nested_dependency_info(base_install_dir)
            pp [:nested_dependency_info,nested_dependency_info]
            # For Aldin: here is dependency info that you use below
            # example values
            # [:nested_dependency_info,
            # {"puppetlabs/concat"=>
            #   [{"name"=>"puppetlabs/stdlib", "version_requirement"=>">= 3.2.0 < 5.0.0"}],
            #  "nanliu/staging"=>[],
            #  "puppetlabs/stdlib"=>[],
            #  "puppetlabs/tomcat"=>
            #   [{"name"=>"puppetlabs/stdlib", "version_requirement"=>">= 4.2.0"},
            #    {"name"=>"puppetlabs/concat", "version_requirement"=>">= 1.0.4"},
            #    {"name"=>"nanliu/staging", "version_requirement"=>">= 0.4.1"}]}]

            dependencies.collect do |dp|
              dp_name     = dp['module']
              dp_module_namespace, dp_module_name = PuppetForge.puppet_forge_namespace_and_module_name(dp_name)
              dp_version  = dp['version'] ? dp['version']['vstring'] : nil
              dp_full_id  = "#{dp_name}"
              dp_full_id += " (#{dp_version})" if dp_version
              # For Rich:
              # this is the part where I put dependencies of dependencies, but they are not propagated correctly
              # so leaving this part for you to implement if you are more familiar with this
              # dp['dependencies'] = parse_dependencies(dp_name, dp_full_id)
              # /tmp/puppet/53b83eca-ea93-463e-990f-f736fc2306bb/staging/metadata.hash_info
              ActiveSupport::HashWithIndifferentAccess.new({
                :name => dp_name, :module_name => dp_module_name,
                :module_namespace => dp_module_namespace, :version => dp_version,
                :full_id => dp_full_id, :module_type => 'component_module', :dependencies => dp['dependencies']
              })
            end
         end
        end

        Remove = "\e[0m\n"
        def normalize_output(output_s)
          output_s.split(Remove).last
        end

        def raise_puppet_forge_error(output_err)
          puppet_forge_err = output_err.split(Remove).first
          raise ErrorUsage, "Puppet Forge Error: #{puppet_forge_err}"
        end

        # hash with forge_name as key and value is an array with dependencies
        def nested_dependency_info(base_install_dir)
          yaml_output = `puppet module list --tree --render-as yaml --modulepath #{base_install_dir}`
          all_imported = YAML.load(yaml_output).values.flatten
          all_imported.inject(Hash.new) do |h,puppet_module|
            h.merge(puppet_module.forge_name => puppet_module.dependencies)
          end
        end
        # For Aldin: use above, which is called once rather than below which we will deprecate
        # also a change is --modulepath #{base_install_dir} so it searches in tmp area we installed in and by virtue gets only
        # relevant info; now teh top level module's dependencies wil be called, but not needed since we have that alraedy
        # no harm including this in what is returned
        # Parse all imported puppet forge modules and find their dependencies
        def parse_dependencies(dp_name, dp_full_id)
          yaml_output         = `puppet module list --tree --render-as yaml`
          all_modules         = YAML.load(yaml_output)
          final_dep_list      = []
          all_imported        = all_modules.values.flatten
          matching_dependency = nil

          all_imported.each do |dependency|
            if dependency.forge_name.eql?(dp_name.gsub('-','/'))
              matching_dependency = dependency
              break
            end
          end

          return [] unless matching_dependency

          nested_depencencies = matching_dependency.dependencies
          nested_depencencies.each do |n_dep|
            namespace, name = n_dep['name'].split('/')
            final_dep_list << {:name => name, :namespace => namespace}
          end

          final_dep_list
        end

      end
    end
  end
end
