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
module DTK
  class Model
    class PPObjectType < String
      # format below can be
      # :s - singular (default)
      # :p - plural
      # :pos - plural or singular
      module Mixin
        def pp_object_type(format = nil)
          self.class.pp_object_type(format)
        end
      end
      module ClassMixin
        def pp_object_type(format = nil)
          PPObjectType.render(self, format)
        end

        def object_type_string
          to_s.split('::').last.gsub(/([a-z])([A-Z])/, '\1 \2').downcase
        end
      end

      def self.render(model_class, format_or_cardinality = nil)
        print_form = SubclassProcessing.print_form(model_class) || model_class.object_type_string()
        string =
          if format_or_cardinality.is_a?(Fixnum)
            cardinality = format_or_cardinality
            if cardinality > 1
              make_plural(print_form)
            else
              print_form
            end
          else
            format = format_or_cardinality || :s
            case format
              when :s then print_form
              when :p then make_plural(print_form)
              when :pos then make_plural(print_form, plural_or_singular: true)
              else fail Error.new("Unexpected format (#{format})")
            end
          end
        new(string)
      end

      def cap
        split(' ').map(&:capitalize).join(' ')
      end

      private

      def self.make_plural(term, opts = {})
        if term =~ /y$/
          opts[:plural_or_singular] ? "#{term[0...-1]}(ies)" : "#{term[0...-1]}ies"
        else
          opts[:plural_or_singular] ? "#{term}(s)" : "#{term}s"
        end
      end
    end
  end
end