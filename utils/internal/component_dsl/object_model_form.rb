module DTK; class ComponentDSL
  class ObjectModelForm
    def self.convert(input_hash)
      new.convert(input_hash)
    end

    class InputHash < Hash
      def initialize(hash={})
        unless hash.empty?()
          replace(convert(hash))
        end
      end
      
      def req(key)
        key = key.to_s
        unless has_key?(key)
          raise ParsingError::MissingKey.new(key)
        end
        self[key]
      end
     private
      def convert(item)
        if item.kind_of?(Hash)
          item.inject(InputHash.new){|h,(k,v)|h.merge(k => convert(v))}
        elsif item.kind_of?(Array)
          item.map{|el|convert(el)}
        else
          item
        end
      end
    end

    class OutputHash < Hash
      def initialize(hash={})
        unless hash.empty?()
          replace(hash)
        end
      end
      def set_if_not_nil(key,val)
        self[key] = val unless val.nil?
      end
    end

    class ParsingError < ErrorUsage
      def initialize(msg='',*args)
        super("component dsl parsing error: #{msg_pp_form(msg,*args)}")
      end

      def self.raise_error_if_not(obj,klass)
        unless obj.kind_of?(klass)
          raise new("Ill-formed fragment (?1); it should be a #{klass.to_s.downcase}",obj)
        end
      end

      def msg_pp_form(msg,*args)
        args.each_with_index do |arg, i|
          msg.gsub!(Regexp.new("\\?#{(i+1).to_s}"),pp_format_arg(arg))
        end
        msg
      end
      def pp_format_arg(arg)
        #TODO: hard-coded format
        format_type = :json
        if format_type == :json 
          if arg.kind_of?(Hash)
            JSON.generate(arg)
          else
            arg.inspect
          end
        else
          arg.inspect
        end
      end
      private :msg_pp_form, :pp_format_arg

      class MissingKey < self
        def initialize(key)
          super("missing key (#{key})")
        end
      end
    end

  end
end; end

