module DTK
  r8_nested_require('module','mixins')
  r8_nested_require('module','component')
  r8_nested_require('module','service')
  r8_nested_require('module','branch')
  class ModuleCommon
    # This has been moved to DTK Common TODO [Haris] replace
    def self.string_has_version_format?(str)
      !!(str =~ /\A\d{1,2}\.\d{1,2}\.\d{1,2}\Z/)
    end

    def self.string_master_or_empty?(object)
      ret =
        if object.nil? 
          true
        elsif object.kind_of?(String)
          object.casecmp("master").eql?(0) || object.casecmp("default").eql?(0)
        end
      !!ret
    end

    # Compares version, return true if same
    def self.versions_same?(str1, str2)
      return true if (string_master_or_empty?(str1) && string_master_or_empty?(str2))
      # ignore prefix 'v' if present e.g. v4.2.3
      return (str1||'').gsub(/^v/,'').eql?((str2||'').gsub(/^v/,''))
    end 
  end
end
