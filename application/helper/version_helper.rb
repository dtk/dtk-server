module Ramaze::Helper
  module VersionHelper

    CURRENT_VERSION = 'master'

    def ret_version()
      version = ret_request_params(:version)
      version && raise_error_if_version_illegal_format(version)
    end

    # we want to support deleting current version
    def ret_version_component()
      version = ret_request_params(:version)
      return CURRENT_VERSION if version && (version.casecmp("CURRENT") == 0 || version.casecmp("MASTER") == 0)
      version && raise_error_if_version_illegal_format(version)
    end

    def is_legal_version_format?(version)
      return true unless version
      ::DTK::ModuleVersion.string_has_version_format?(version)
    end

    def raise_error_if_version_illegal_format(version)
      unless is_legal_version_format?(version)
        raise ::DTK::ErrorUsage::BadVersionValue.new(version)
      end
      version
    end

  end
end
