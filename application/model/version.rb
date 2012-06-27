module DTK
  module VersionMixin
    DefaultVersion = 'master'
    def has_default_version?()
      update_object!(:version)[:version] == DefaultVersion
    end
  end
end
