module DTK
  class ModuleVersion < String
    def self.create_for_assembly(assembly)
      AssemblyModule.new(assembly)
    end

    def self.string_has_version_format?(str)
      string_has_numeric_version_format?(str) or AssemblyModule.string_has_version_format?(str)
    end

    def self.string_has_numeric_version_format?(str)
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

    class AssemblyModule < self
      attr_reader :assembly_name

      def self.string_has_version_format?(str)
        !!(str =~ /^assembly--/)
      end

     private
      def initialize(assembly)
        @assembly_name = assembly.get_field?(:display_name)
        super(version_string(@assembly_name))
      end

      def version_string(assembly_name)
        "assembly--#{assembly_name}"
      end
    end
  end
end
