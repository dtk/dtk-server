module DTK; class ComponentModuleRef
  class VersionInfo
    class Assignment < self
      def initialize(string)
        @version = string
      end

      attr_reader :version      

      def self.reify?(string_or_obj)
        version_string = 
          if string_or_obj.kind_of?(String) then string_or_obj
          elsif string_or_obj.kind_of?(ComponentModuleRef) then string_or_obj[:version_info]
          end
        if version_string  and ModuleCommon.string_has_version_format?(version_string)
          new(version_string)
        end
      end

      def to_s()
        @version.to_s()
      end
    end

    class Constraint < self
      def ret_version()
        if is_scalar?() then is_scalar?()
        elsif empty? then nil
        else
          raise Error.new("Not treating the version type (#{ret.inspect})")
        end
      end

      def self.reify?(constraint=nil)
        if constraint.nil? then new()
        elsif constraint.kind_of?(Constraint) then constraint
        elsif constraint.kind_of?(String) then new(constraint)
        elsif constraint.kind_of?(Hash) and constraint.size == 1 and constraint.keys.first == "namespace"
          #MOD_RESTRUCT: TODO: need to decide if depracting 'namespace' key
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

      def is_scalar?()
        @value if @type == :scalar
      end

      def empty?()
        @type == :empty
      end
      
      def to_s()
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
