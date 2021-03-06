#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require File.expand_path('../../utils/internal/opts', File.dirname(__FILE__))

module DTK
  class ErrorUsage < Error
    r8_nested_require('usage', 'parsing')
    # dsl_not_supported must be after parsing
    r8_nested_require('usage', 'dsl_not_supported')
    r8_nested_require('usage', 'warning')

    attr_reader :donot_log_error
    def initialize(msg = '', *args)
      @donot_log_error = (args.last.is_a?(::DTK::Opts) and args.last[:log_error] == false)
      super(msg, *args)
    end

    def add_tag!(tag)
      @tags ||= []
      @tags << tag unless @tags.include?(tag)
      self
    end

    def has_tag?(tag)
      (@tags || []).include?(tag)
    end

    private

    def add_line!(msg, line, ident = 0)
      msg << "#{' ' * ident}#{line}\n"
    end

    def sentence_capitalize(line)
      split = line.split
      first = split.shift.capitalize
      ([first] + split).join(' ')
    end

    # TODO: make second argument be polymorphic to handle things like wrong type, wrong name
    class BadParamValue < self
      def initialize(param, enum_vals = nil)
        super(msg(param, enum_vals))
      end

      private

      def msg(param, enum_vals)
        msg = "Paramater '#{param}' has an illegal value"
        if enum_vals
          msg << "; most be one of (#{enum_vals.join(',')})"
        end
        msg
      end
    end

    class BadVersionValue < self
      def initialize(version_value)
        super(msg(version_value))
      end

      def msg(version_value)
        "Version has an illegal value '#{version_value}', format needed: '##.##.##'"
      end
    end
  end

  # TODO: nest these also under ErrorUsage
  class ErrorsUsage < ErrorUsage
    def initialize
      @errors = []
    end

    def <<(err)
      @errors << err
    end

    def empty?
      @errors.empty?()
    end

    def to_s
      if @errors.size == 1
        @errors.first.to_s()
      elsif @errors.size > 1
        "\n" + @errors.map(&:to_s).join("\n")
      else #no errors shoudl not be called
        'No errors'
      end
    end
  end

  # TODO: move over to use nested classeslike above
  class ErrorIdInvalid < ErrorUsage
    def initialize(id, object_type)
      super(msg(id, object_type))
    end

     def msg(id, object_type)
       "Illegal id (#{id}) for #{object_type}"
     end
  end

  class ErrorNameInvalid < ErrorUsage
    def initialize(name, object_type)
      super(msg(name, object_type))
    end

     def msg(name, object_type)
       "Illegal name (#{name}) for #{object_type}"
     end
  end

  class ErrorNameAmbiguous < ErrorUsage
    def initialize(name, matching_ids, object_type)
      super(msg(name, matching_ids, object_type))
    end

     def msg(name, matching_ids, object_type)
       "Ambiguous name (#{name}) for #{object_type} which matches ids: #{matching_ids.join(',')}"
     end
  end

  class ErrorNameDoesNotExist < ErrorUsage
    def initialize(name, object_type, augment_string = nil)
      super(msg(name, object_type, augment_string))
      @name_param = name
      @object_type = object_type
    end

    def qualify(augment_string)
      self.class.new(@name_param, @object_type, augment_string)
    end

    def msg(name, object_type, augment_string)
      msg = "No object of type #{object_type} with name '#{name}' exists"
      if augment_string
        msg << " #{augment_string}"
      end
      msg
    end
  end

  class ErrorConstraintViolations < ErrorUsage
    def initialize(violations)
       super(msg(violations), :ConstraintViolations)
    end

    private

    def msg(violations)
      return ('constraint violation: ' + violations) if violations.is_a?(String)
      v_with_text = violations.compact
      if v_with_text.size < 2
        return 'constraint violations'
      elsif v_with_text.size == 2
        return "constraint violations: #{v_with_text[1]}"
      end
      ret = 'constraint violations: '
      ret << (v_with_text.first == :or ? '(atleast) one of ' : '')
      ret << "(#{v_with_text[1..v_with_text.size - 1].join(', ')})"
    end
  end

  class ErrorUserInputNeeded < ErrorUsage
    def initialize(needed_inputs)
      super()
      @needed_inputs = needed_inputs
    end

    def to_s
      ret = "following inputs are needed:\n"
      @needed_inputs.each do |k, v|
        ret << "  #{k}: type=#{v[:type]}; description=#{v[:description]}\n"
      end
      ret
    end
  end

  class VersionExist < ErrorUsage
    def initialize(version, module_name)
      super(msg(version, module_name))
    end

    def msg(version, module_name)
      "Version '#{version}' exists already for module '#{module_name}'!"
    end
  end
end
