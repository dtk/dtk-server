# TODO: ; a possible enhancement is to calling puppet in process since we have puppet loaded already
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
          Open3.popen3(command) do |_stdin, stdout, stderr, _wait_thr|
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

        def check_for_dependencies(base_install_dir, _module_name, hash_info)
          installed_module = (hash_info['installed_modules']||[]).first

          if dependencies = full_recursive_dependencies(installed_module)
            nested_dependency_info = nested_dependency_info(base_install_dir)
            dependencies.collect do |dp|
              dp_name     = dp['module']
              dp_module_namespace, dp_module_name = PuppetForge.puppet_forge_namespace_and_module_name(dp_name)
              dp_version  = dp['version'] ? dp['version']['vstring'] : nil
              dp_full_id  = "#{dp_name}"
              dp_full_id += " (#{dp_version})" if dp_version
              dp['dependencies'] = nested_dependency_info[dp_name.gsub('-', '/')]
              ActiveSupport::HashWithIndifferentAccess.new(                name: dp_name, module_name: dp_module_name,
                module_namespace: dp_module_namespace, version: dp_version,
                full_id: dp_full_id, module_type: 'component_module')
            end
         end
        end

        def full_recursive_dependencies(installed_module)
          return [] unless installed_module
          result = installed_module['dependencies'].collect do |dependency|
            [dependency].concat(full_recursive_dependencies(dependency))
          end
          result.flatten
        end

        REMOVE_PATTERN = "\e[0m\n"

        def normalize_output(output_s)
          output_s.split(REMOVE_PATTERN).last
        end

        def raise_puppet_forge_error(output_err)
          puppet_forge_err = output_err.split(REMOVE_PATTERN).first
          raise ErrorUsage, "Puppet Forge Error: #{puppet_forge_err}"
        end

        # hash with forge_name as key and value is an array with dependencies
        def nested_dependency_info(base_install_dir)
          yaml_output = `puppet module list --tree --render-as yaml --modulepath #{base_install_dir}`
          all_imported = YAML.load(yaml_output).values.flatten
          all_imported.inject({}) do |h,puppet_module|
            normalized_dependencies = []
            puppet_module.dependencies.each do |deps|
              matching = all_imported.detect{|imported| imported.forge_name.eql?(deps['name'])}
              normalized_dependencies << {
                # have to set 'module' and 'path' to be able to successfully create dependency
                'module' => matching.forge_name.gsub('/', '-'),
                'version' => matching.version,
                'path' => matching.modulepath
              }
            end
            h.merge(puppet_module.forge_name => normalized_dependencies)
          end
        end
      end
    end
  end
end
