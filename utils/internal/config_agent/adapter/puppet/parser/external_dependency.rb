module DTK; class ConfigAgent
  class Adapter::Puppet
    class ExternalDependency
      class ParsedForm < Hash
        # TODO: stub to put in logic about matching versions now in
        # server/application/model/module/module/dsl_mixin/external_refs.rb
      end

      def parsed_form?
        @parsed_dependency
      end

      def initialize(name, version_constraints_string)
        @name = name
        @version_constraints_string = version_constraints_string
        @parsed_dependency = nil
        # added protection in case we get unexpected form
        begin
          @parsed_dependency = ParsedForm.new.merge(
            name: name,
            version_constraints: parse_constraints_string(version_constraints_string)
          )
         rescue Exception => e
          Log.error("error parsing version constraints string: #{version_constraints_string}")
          Log.error_pp([e, e.backtrace[0..5]])
        end
      end

      private

      # TODO: too many restrictions; such as that version nums can only be single digit
      def parse_constraints_string(versions_string)
        ret = []
        return ret if versions_string.nil?
        rest_string = parse_one_constraint!(ret, versions_string)
        if rest_string
          parse_one_constraint!(ret, rest_string)
        end
        ret
      end

      ConstraintRegex1 = /^\s*([>=<]+)\s*(\d\.*\d*\.*\d*)\s*(.*$)/
      ConstraintRegex2 = /^\s*(\d)\.x\s*$/
      # returns rest of string after parsing
      # :rest, :match, which has keys :version, :constraint
      def parse_one_constraint!(ret, versions_string)
        rest_string = nil
        if match = versions_string.match(ConstraintRegex1)
          ret << { version: normalize_to_three_parts(match[2]), constraint: match[1] }
          rest_string =  match[3] unless match[3].empty?
        elsif match = versions_string.match(ConstraintRegex2)
          ret << { version: normalize_to_three_parts(match[1]), constraint: '>=' }
          ret << { version: normalize_to_three_parts(match[1].to_i + 1), constraint: '<' }
        else
          raise Error.new("error parsing version constraints string: #{versions_string})")
        end
        rest_string
      end

      # TODO: assumption that version has form
      # x.y.z, x.y, or x
      ThreeParts = /\d\.\d\.\d/
      TwoParts = /\d\.\d/
      def normalize_to_three_parts(version)
        if version.is_a?(Fixnum)
          "#{version}.0.0"
        elsif version =~ ThreeParts
          version
        elsif version =~ TwoParts
          "#{version}.0"
        else
          "#{version}.0.0"
        end
      end
    end
  end
end; end
