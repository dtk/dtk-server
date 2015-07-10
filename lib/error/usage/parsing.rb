module DTK; class ErrorUsage
  class Parsing < ErrorUsage::DSLParsing #TODO: cleanup this is coming from dtk_common
    r8_nested_require('parsing', 'yaml')
    r8_nested_require('parsing', 'term')
    r8_nested_require('parsing', 'legal_values')
    r8_nested_require('parsing', 'legal_value')
    r8_nested_require('parsing', 'wrong_type')
    r8_nested_require('parsing', 'params')

    # args as last arguments, can have
    # ...Params,Opts
    # ...Params
    # ...Opts
    # ..
    def initialize(msg = '', *args)
      processed_msg, params, opts = Params.process(msg, *args)
      @params = params

      # if file_path is an option than see if there is an explicit variable in msg for file_path; if so substitue and deleet
      # so parent does not add it to end
      if file_path = opts[:file_path]
        if Params.substitute_file_path?(processed_msg, file_path)
          opts.delete(:file_path)
        end
      end

      if free_var = Params.any_free_vars?(processed_msg)
        Log.error("The following error message has free variable: #{free_var}")
      end

      if error_prefix = opts.delete(:error_prefix)
        processed_msg = "#{error_prefix}: #{processed_msg}"
      end

      # TODO: cleanup so parent takes opts, rather than opts_or_file_path
      opts_or_file_path =
        if opts.empty?
          { caller_info: true }
        elsif opts[:file_path]
          if opts.size > 1
            fail Error.new('Not supported yet, need to cleanup so parent takes opts, rather than opts file path')
          else
            opts[:file_path]
          end
        else
          opts
        end
      super(processed_msg, opts_or_file_path)
    end

    def self.trap(opts = {}, &_block)
      ret = nil
      begin
        ret = yield
        if opts[:only_return_error] && !ret.is_a?(ErrorUsage::Parsing)
          ret = nil
        end
      rescue ErrorUsage::Parsing => e
        ret = e
      end
      ret
    end

    def self.is_error?(obj)
      obj.is_a?(ErrorUsage::Parsing)
    end

    def self.raise_error_if_value_nil(v, opts = {})
      if v.nil?
        if err_params = opts[:err_params]
          err_msg = opts[:err_msg] || 'Value of (?1) should not be nil'
          fail new(err_msg, err_params)
        else
          err_msg = opts[:err_msg] || 'Value should not be nil'
          fail new(err_msg)
        end
      end
      v
    end

    def self.raise_error_if_not(obj, klass, opts = {})
      # TODO: put in pretty print of "#{klass}
      unless obj.is_a?(klass)
        fragment_type = opts[:type] || 'fragment'
        for_text = (opts[:for] ? "for #{opts[:for]}; " : nil)
        err_msg = opts[:err_msg] || "Ill-formed #{fragment_type} #{error_obj_ref(obj)}#{for_text}it should be a #{klass}"
        err_params = opts[:err_params] || Params.new(obj: obj)
        if context = opts[:context]
          err_msg << '; it appears in ?context'
          err_params.merge!(context: context)
        end
        fail new(err_msg, err_params)
      end
      obj
    end
    # TODO: combine these two
    def self.raise_error_unless(object, legal_values_input_form = [], &legal_values_block)
      legal_values = LegalValues.reify(legal_values_input_form, &legal_values_block)
      unless legal_values.match?(object)
        fail WrongType.new(object, legal_values, &legal_values_block)
      end
      object
    end

    private

    def self.error_obj_ref(obj)
      if obj.is_a?(Hash) || obj.is_a?(Array)
        "?obj\n"
      else
        '(?obj) '
      end
    end

    def self.create_with_hash_params(msg, hash_params, *args)
      new(msg, *Params.add_to_array(args, hash_params))
    end
  end
end; end
