module DTK; class ModuleBranch
  class Location
    class Params < Hash
      # module_name, version, and namespace are common params for local and remote
      def module_name(opts={})
        ret = self[:module_name]
        if opts[:with_namespace]
          unless ns = module_namespace_name()
            raise Error.new("Unexpected that self does not have namespace set")
          end
          ret = Namespace.join_namespace(ns, ret)
        end
        ret
      end

      def module_namespace_name()
        self[:namespace]
      end

      def module_type()
        self[:module_type]
      end
      def version()
        self[:version]
      end
      def namespace()
        self[:namespace]
      end
      def source_name()
        self[:source_name]
      end
      def initialize(params)
        unless params.kind_of?(self.class)
          validate(params)
        end
        replace(params)
      end

      def pp_module_name(opts={})
        ret = module_name
        if version
          ret << ":#{version}"
        end

        module_namespace_name ? "#{module_namespace_name}/#{ret}" : ret
      end

     private
      def validate(params)
        unless (bad_keys = params.keys - all_keys()).empty?
          raise Error.new("Illegal key(s): #{bad_keys.join(',')}")
        end
        missing_required = required_keys().select{|key|params[key].nil?}
        unless missing_required.empty?
          raise Error.new("Required key(s): #{missing_required.join(',')}")
        end
      end
      def all_keys()
        legal_keys().map{|k|optional?(k)||k}
      end
      def required_keys()
        legal_keys().reject{|k|optional?(k)}
      end
      def optional?(k)
        k = k.to_s
        if k =~ /\?$/
          k.gsub(/\?$/,'').to_sym
        end
      end
    end
  end
end; end
