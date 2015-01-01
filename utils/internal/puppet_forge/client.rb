require 'active_support/hash_with_indifferent_access'

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
            module_dependencies = check_for_dependencies(pf_module_name, output_hash)
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

          output_s = `#{command}`

          # we remove invalid characters to get to JSON response
          output_s = normalize_output(output_s)
          output_hash   = JSON.parse(output_s)
          output_hash['install_dir'] += "/#{PuppetForge.puppet_forge_module_name(pf_module_name)}"
          output_hash
        end

        def check_for_dependencies(module_name, json)
          if json['installed_modules'] && main_module = json['installed_modules'].first
            main_module['dependencies'].collect do |dp|
              dp_name     = dp['module']
              dp_module_namespace, dp_module_name = PuppetForge.puppet_forge_namespace_and_module_name(dp_name)
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
        end

        def normalize_output(output_s)
          output_s.split("\e[0m\n").last
        end

      end
    end
  end
end
