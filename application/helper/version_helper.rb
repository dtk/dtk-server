module Ramaze::Helper
  module VersionHelper
    def ret_version
      if version_string = ret_request_params(:version)
        unless version = ::DTK::ModuleVersion.ret(version_string)
          raise ::DTK::ErrorUsage::BadVersionValue.new(version_string)
        end
        version
      end
    end
  end
end
