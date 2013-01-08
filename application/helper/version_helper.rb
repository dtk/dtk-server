module Ramaze::Helper
  module VersionHelper
    def is_legal_version_format?(version)
      return true unless version
      !!(version =~ /^[0-9]+\.[0-9]+\.[0-9]+$/)
    end

    def raise_error_if_version_illegal_format(version)
      unless is_legal_version_format?(version)
        raise ::DTK::ErrorUsage::BadParamValue.new(:version)
      end
    end

  end
end
