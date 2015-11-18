module Ramaze::Helper
  module VersionHelper
    def ret_version
      if version_string = ret_request_params(:version)
        unless version = ::DTK::ModuleVersion.ret(version_string)
          fail ::DTK::ErrorUsage::BadVersionValue.new(version_string)
        end
        version
      end
    end

    def compute_latest_version(module_type)
      versions = []
      all_branches = module_type.get_module_branches.select{ |br| br[:version].eql?('master') || br[:version].match(/\A\d{1,2}\.\d{1,2}\.\d{1,2}\Z/) }
      if all_branches.size == 1
        version = all_branches.first[:version]
        return version.eql?('master') ? nil : version
      else
        all_branches.each do |branches|
          version = branches[:version]
          versions << (version.eql?('master') ? "0" : version.to_s)
        end
      end
      return_latest(versions)
    end

    def return_latest(versions)
      versions.sort!()
      versions.last
    end
  end
end
