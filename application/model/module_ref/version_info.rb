module DTK; class ModuleRef
  class VersionInfo
    DEFAULT_VERSION = nil

    class Assignment < self
      def initialize(version_string)
        @version_string = version_string
      end

      attr_reader :version_string

      def self.reify?(object)
        version_string =
          if object.is_a?(String)
            ModuleVersion.string_master_or_empty?(object) ? DEFAULT_VERSION : object
          elsif object.is_a?(ModuleRef)
            object[:version_info]
          end

         if version_string 
           if ModuleVersion::Semantic.legal_format?(version_string)  
             new(version_string)
           else
            raise Error.new("Unexpected form of version string (#{version_string})")
          end
        end
      end

      def to_s
        @version_string
      end
    end

    class Constraint < self
      def ret_version
        if is_scalar?() then is_scalar?()
        elsif empty? then nil
        else
          raise Error.new("Not treating the version type (#{ret.inspect})")
        end
      end

      def self.reify?(constraint=nil)
        if constraint.nil? then new()
        elsif constraint.is_a?(Constraint) then constraint
        elsif constraint.is_a?(String) then new(constraint)
        elsif constraint.is_a?(Hash) && constraint.size == 1 && constraint.keys.first == "namespace"
          # MOD_RESTRUCT: TODO: need to decide if depracting 'namespace' key
          Log.info("Ignoring constraint of form (#{constraint.inspect})")
          new()
        else
          raise Error.new("Constraint of form (#{constraint.inspect}) not treated")
        end
      end

      def include?(version)
        case @type
        when :empty
          nil
        when :scalar
          @value == version
        end
      end

      def is_scalar?
        @value if @type == :scalar
      end

      def empty?
        @type == :empty
      end

      def to_s
        case @type
        when :scalar
          @value.to_s
        end
      end

      private

      def initialize(scalar=nil)
        @type = (scalar ? :scalar : :empty)
        @value = scalar
      end
    end
  end
end; end
