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

    def self.string_master_or_emtpy?(str)
      str.nil? || str.empty? || str.casecmp("master").eql?(0) || str.casecmp("default").eql?(0)
    end

    # Compares version, return true if same
    def self.versions_same?(str1, str2)
      return true if (string_master_or_emtpy?(str1) && string_master_or_emtpy?(str2))
      # ignore prefix 'v' if present e.g. v4.2.3
      return (str1||'').gsub(/^v/,'').eql?((str2||'').gsub(/^v/,''))
    end 
  end
end
