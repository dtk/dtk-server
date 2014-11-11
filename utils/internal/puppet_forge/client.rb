r8_require('errors')

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

          # augmented data
          output['install_dir'] += "/#{dir_name}"

          output
        end

      end
    end

  end
end