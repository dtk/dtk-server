module DTK; class ConfigAgent
  class Adapter::Puppet
    class ExternalDependency

      class ParsedForm < Hash
        # TODO: stub to put in logic about matching versions now in
        # server/application/model/module/module/dsl_mixin/external_refs.rb
      end

      def parsed_form?()
        @parsed_dependency
      end
      def initialize(name,version_constraints_string)
        @name = name
        @version_constraints_string = version_constraints_string
        @parsed_dependency = nil
        # added protection in case we get unexpected form
        begin
          @parsed_dependency = ParsedForm.new.merge(
            :name => name, 
            :version_constraints => parse_constraints_string(version_constraints_string) 
          )
         rescue Exception => e
          Log.error("error parsing version constraints string: #{version_constraints_string}")
          Log.error_pp([e,e.backtrace[0..5]])
        end
      end
     private
      def parse_constraints_string(versions_string)
        ret = []
        return ret if versions_string.nil?

        multiple_versions = []
        # multiple_versions = versions.split(' ')
        if matched_versions = versions_string.match(/(^[>=<]+\s*\d\.\d\.\d)\s*([>=<]+\s*\d\.\d\.\d)*/)
          multiple_versions << matched_versions[1] if matched_versions[1]
          multiple_versions << matched_versions[2] if matched_versions[2]
        else
          raise Error.new("error parsing version constraints string: #{versions_string})")
        end
        multiple_versions.each do |version|
          match = version.to_s.match(/(^>*=*<*)(.+)/)
        ret << {:version=>match[2], :constraint=>match[1]}
        end
        ret
      end
    end
  end
end; end
    
