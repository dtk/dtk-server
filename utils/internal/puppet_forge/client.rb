# TODO: DTK-1794; in code that iterates over depenedncies; see if you have to look at dpendencies of dependenciee;
# and if so assuming if want listof all modles and their dependencies wil have to throw out dups

r8_require('errors')
require 'securerandom'
require 'active_support/hash_with_indifferent_access'


module DTK
  module PuppetForge
    MODULE_NAME_SEPARATOR = '-'
    def self.puppet_forge_namespace_and_module_name(pf_module_name)
      pf_module_name.split(MODULE_NAME_SEPARATOR, 2)
    end
    def self.puppet_forge_module_name(pf_module_name)
      puppet_forge_namespace_and_module_name(pf_module_name).last
    end

    class Error < Exception
    end

    class Module
      attr_reader :path
      def initialize(hash)
        @module  = hash['module']
        @version = hash['version']
        @file    = hash['file']
        @path    = "#{hash['path']}/#{PuppetForge.puppet_forge_module_name(@module)}"
      end

      def default_local_module_name
        PuppetForge.puppet_forge_module_name(@module)
      end
    end

    class LocalCopy < Hash
      attr_reader :base_install_dir,:module_dependencies
      def initialize(output_hash,base_install_dir,module_dependencies)
        super()
        merge!(output_hash)
        @base_install_dir = base_install_dir
        @module_dependencies = module_dependencies
      end

      def modules(opts={})
        self.class.modules(self['installed_modules']||[],opts)
      end

      def delete_base_install_dir?()
        self.class.delete_base_install_dir?(@base_install_dir)
      end
      def self.delete_base_install_dir?(base_install_dir)
        FileUtils.rm_rf(base_install_dir)
      end

      def self.random_install_dir()
        "/tmp/puppet/#{SecureRandom.uuid}"
      end

     private
      def self.modules(installed_modules,opts={})
        ret = Array.new
        installed_modules.each do |installed_module|
          # TODO: DTK-1794; put in logic that checks whether teh array :remove is inopts and if so does not put in any module that matches
          ret << Module.new(installed_module)
          deps = installed_module['dependencies']
          if deps and ! deps.empty?
            ret += modules(deps,opts)
          end
        end
        ret
      end
    end

    #
    # Wrapper around puppet CLI (distributed via puppet gem)
    #
    class Client
      class << self

        # user and name sepparator used by puppetforge
        def install(pf_module_name, puppet_version=nil, force=false)
          raise DTK::Puppet::ModuleNameMissing, "Puppet forge module name not provided" if pf_module_name.nil? || pf_module_name.empty?

          dir_name         = PuppetForge.puppet_forge_module_name(pf_module_name)
          base_install_dir = LocalCopy.random_install_dir()

          command  = "puppet _3.4.0_ module install #{pf_module_name} --render-as json --target-dir #{base_install_dir} --modulepath #{base_install_dir}"
          command += " --version #{puppet_version}" if puppet_version && !puppet_version.empty?
          command += " --force"              if force

          ret = nil
          begin 
            output_s = `#{command}`

            # we remove invalid characters to get to JSON response
            output_s = normalize_output(output_s)
            output_hash   = JSON.parse(output_s)
            output_hash['install_dir'] += "/#{dir_name}"
            unless 'success'.eql?(output_hash['result'])
              raise ErrorUsage, "Puppet Forge Error: #{output_hash['error']['oneline']}"
            end
            module_dependencies = check_for_dependencies(pf_module_name, output_hash)
            ret = LocalCopy.new(output_hash,base_install_dir,module_dependencies)
          rescue => e
            LocalCopy.delete_base_install_dir?()
            raise e
          end
          ret
        end

        #
        # Verify if puppet forge module name is supported, to new name
        #

        def is_module_name_valid?(puppet_forge_name, module_name)
          pf_module_name = PuppetForge.puppet_forge_module_name(puppet_forge_name)

          unless module_name
            raise ErrorUsage.new("Please provide module name")
          end

          unless module_name.eql?(pf_module_name)
            raise ErrorUsage.new("Install with module name (#{module_name}) unequal to puppet forge module name (#{pf_module_name}) is currently not supported.")
          end
        end

      private

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
          output_s = output_s.split("\e[0m\n").last
          output_s
        end

      end
    end

  end
end
