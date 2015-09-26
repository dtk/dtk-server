module DTK; class Task
  class Template
    class ParsingError < ErrorUsage::Parsing
      def initialize(msg, *args_x)
        args = Params.add_opts(args_x, error_prefix: ErrorPrefix, caller_info: true)
        super(msg, *args)
      end
      ErrorPrefix = 'Workflow parsing error'

      class MissingComponentOrActionKey < self
        include Serialization

        def initialize(serialized_el, opts = {})
          all_legal = Constant.all_string_variations(:ComponentsOrActions).join(', ')
          msg = ''
          if stage = opts[:stage]
            msg << "In stage '#{stage}', missing "
          else
            msg << 'Missing '
          end
          msg << "a component or action field (one of: #{all_legal}) in ?1"
          super(msg, serialized_el)
        end
      end
    end
  end
end; end
