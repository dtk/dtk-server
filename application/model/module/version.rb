module DTK
  class ModuleVersion < String
    def self.create_for_assembly(assembly)
      AssemblyModule.new(assembly.get_field?(:display_name))
    end

    def self.create_from_string(str)
      if Semantic.legal_format?(str)
        Semantic.create_from_string(str)
      elsif AssemblyModule.legal_format?(str)
        AssemblyModule.create_from_string(str)
      end
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

    class Semantic < self
      def self.create_from_string(str)
        new(str)
      end
      def self.legal_format?(str)
        !!(str =~ /\A\d{1,2}\.\d{1,2}\.\d{1,2}\Z/)
      end
    end

    class AssemblyModule < self
      attr_reader :assembly_name

      def self.legal_format?(str)
        !!(str =~StringPattern)
      end
      def self.create_from_string(str)
        if str =~ StringPattern
          assembly_name = $1
          new(assembly_name)
        end
      end
      StringPattern = /^assembly--(.+$)/

     private
      def initialize(assembly_name)
        @assembly_name = assembly_name
        super(version_string(assembly_name))
      end

      def version_string(assembly_name)
        "assembly--#{assembly_name}"
      end
    end
  end
end
