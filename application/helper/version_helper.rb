module Ramaze::Helper
  module VersionHelper
    def ret_version()
      version = ret_request_params(:version)
      version && raise_error_if_version_illegal_format(version)
    end
    def is_legal_version_format?(version)
      return true unless version
      !!(version =~ /\A\d{1,2}\.\d{1,2}\.\d{1,2}\Z/)
    end

    def raise_error_if_version_illegal_format(version)
      unless is_legal_version_format?(version)
        raise ::DTK::ErrorUsage::BadVersionValue.new(version)
      end
      version
    end

  end
end
