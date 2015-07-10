module DTK
  class ModuleVersion < String
    def self.ret(obj)
      if obj.nil?
        nil
      elsif obj.is_a?(String)
        if Semantic.legal_format?(obj)
          Semantic.create_from_string(obj)
        elsif AssemblyModule.legal_format?(obj)
          AssemblyModule.create_from_string(obj)
        end
      elsif obj.is_a?(Assembly)
        AssemblyModule.new(obj.get_field?(:display_name))
      else
        fail Error.new("Unexpected object type passed to ModuleVersion.ret (#{obj.class})")
      end
    end

    def self.string_master_or_empty?(object)
      ret =
        if object.nil?
          true
        elsif object.is_a?(String)
          object.casecmp('master').eql?(0) || object.casecmp('default').eql?(0)
        end
      !!ret
    end

    # Compares version, return true if same
    def self.versions_same?(str1, str2)
      return true if (string_master_or_empty?(str1) && string_master_or_empty?(str2))
      # ignore prefix 'v' if present e.g. v4.2.3
      (str1 || '').gsub(/^v/, '').eql?((str2 || '').gsub(/^v/, ''))
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

      def get_assembly(mh)
        sp_hash = {
          cols: [:id, :group_id, :display_name],
          filter: [:and, [:eq, :display_name, @assembly_name], [:neq, :datacenter_datacenter_id, nil]]
        }
        rows = Assembly::Instance.get_objs(mh.createMH(:assembly_instance), sp_hash)
        if rows.size == 1
           rows.first
        elsif rows.size == 0
          fail Error.new("Unexpected that no assemblies associated with (#{inspect})")
        else
          fail Error.new("Unexpected that #{rows.size} assemblies are associated with (#{inspect})")
        end
      end

      def self.legal_format?(str)
        !!(str =~ StringPattern)
      end
      def self.create_from_string(str)
        if str =~ StringPattern
          assembly_name = Regexp.last_match(1)
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
