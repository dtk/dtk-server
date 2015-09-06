require 'mustache'

module DTK
  module MustacheTemplate
    def self.needs_template_substitution?(string)
      # will return true if string has mustache template attributes '{{ variable }}'
      if string
        string =~ HasMustacheVarsRegExp
      end
    end
    HasMustacheVarsRegExp = /\{\{.+\}\}/

    # block_for_err takes mustache_gem_err,string
    # opts can have keys
    #   :file_path
    #   :remove_empty_lines (Booelan)
    def self.render(string, attr_val_pairs, opts={})
      begin
        ::Mustache.raise_on_context_miss = true
        ret = ::Mustache.render(string, attr_val_pairs)
        if opts[:remove_empty_lines]
          # extra empty lines can be due to Mustache for loop behavior
          ret = (ret || '').gsub(/\|(\r?\n)+\|/m, "|\n|")
        end
        ret
       rescue ::Mustache::Parser::SyntaxError => e
        fail MustacheTemplateError::SyntaxError.new(e.message, opts)
       rescue ::Mustache::ContextMiss => e
        fail MustacheTemplateError::MissingVar.create(e.message, opts)
      end
    end
  end

  class MustacheTemplateError < ErrorUsage
    def initialize(err_msg)
      @error_message = err_msg
    end
    attr_reader :error_message

    def to_s
      @error_message
    end
    
    private

    def add_file_path?(err_msg, opts = {})
      file_path = opts[:file_path]
      file_path ? "#{err_msg} '#{file_path}'" : err_msg
    end

    class SyntaxError < self
      def initialize(err_msg, opts = {})
        super("#{add_file_path?('Unable to parse Mustache template', opts)}:\n#{err_msg}")
      end
    end

    class MissingVar < self
      def self.create(err_msg, opts = {})
        if err_msg =~ /^Can't find ([^\s]+) in/
          missing_var = Regexp.last_match(1)
          MissingVar.new(missing_var, opts)
        else
          MustacheTemplateError.new(add_file_path?(err_msg, opts))
        end
      end

      attr_reader :missing_var

      private

      def initialize(missing_var, opts = {})
        super(add_file_path?("Mustache variable '#{missing_var}' is not bound in mustache template", opts))
        @missing_var = missing_var
      end
    end
  end
end





