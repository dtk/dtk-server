module DTK
  r8_nested_require('module','mixins')
  r8_nested_require('module','component')
  r8_nested_require('module','service')
  r8_nested_require('module','branch')
  class ModuleCommon
    def self.string_has_version_format?(str)
      !!(str =~ /\A\d{1,2}\.\d{1,2}\.\d{1,2}\Z/)
    end
  end
end
