require 'mustache'

module DTK
  class MustacheTemplateError < Exception
    attr_reader :error_message
    def initialize(error_message=nil)
      @error_message = error_message
    end

    class MissingVar < self
      attr_reader :missing_var
      def initialize(missing_var)
        super()
        @missing_var = missing_var
      end
    end
  end

  module MustacheTemplateMixin
    def needs_template_substitution?(string)
      # will return true if string has mustache template attributes '{{ variable }}'
      if string
        string =~ HasMustacheVarsRegExp
      end
    end
    HasMustacheVarsRegExp = /\{\{.+\}\}/

    # block_for_err takes mustache_gem_err,string
    def bind_template_attributes_utility(string, attr_val_pairs)
      # using Mustache gem to extract attribute values; raise error if unbound attributes
      begin
        ::Mustache.raise_on_context_miss = true
        ::Mustache.render(string, attr_val_pairs)
      rescue ::Mustache::ContextMiss => mustache_gem_err
        str_err = mustache_gem_err.message
        if str_err =~ /^Can't find ([^\s]+) in/
          missing_var = $1
          raise MustacheTemplateError::MissingVar.new(missing_var)
        else
          raise MustacheTemplateError.new(str_err)
        end
      end
    end

  end
end
