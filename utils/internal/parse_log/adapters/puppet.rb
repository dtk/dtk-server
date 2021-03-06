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
# TODO: move things common to here and chef to ParseLogAdapter
module XYZ
  module ParseLogAdapter
    class Puppet
      def self.parse(lines)
        ret = LogSegments.new
        current_segment = nil
        lines.each do |line|
          next if Prune.find { |prune_pat| line =~ prune_pat }
          if match = Pattern.find { |_k, pat| line =~ pat }
            ret << current_segment if current_segment
            current_segment = LogSegment.create(match[0], line)
          elsif current_segment
            current_segment << line
          end
        end
        ret << current_segment if current_segment
        ret.post_process!()
      end

      def self.log_complete?(lines)
        lines.reverse_each do |l|
          return true if l =~ /Finished catalog run/
          return true if l =~ /Puppet \(info\): \(end\)/
        end
        nil
      end

      private

      Prune =
        [
         /\/File\[\//
        ]

      # order is important because of subsumption
      Pattern =  Aux.ordered_hash(
        [
         { debug: /\(debug\)/ },
         { info: /\(info\)/ },
         { notice: /\(notice\)/ },
         { error: /\(err\)/ }
        ]
      )

      public

      class LogSegments < ::XYZ::LogSegments
        # TODO: may use just for testing; if so deprecate
        def pp_form_summary
          if @complete
            if has_error?()
              error_segment = error_segment()
              "complete with error\n" + (error_segment ? Aux.pp_form(error_segment) : '')
            else
              "complete and ok\n"
            end
          else
            if has_error?()
              error_segment = error_segment()
              "incomplete with error\n" + (error_segment ? Aux.pp_form(error_segment) : '')
            else
              "incomplete and no error yet\n"
            end
          end
        end

        def post_process!
          @complete = complete?()
          # TODO: code to look fro specfic errors
          #           specific_error = nil
          #           PossibleErrors.each do |err|
          #             if err.isa?(segments_from_error)
          #               specific_error = err.new(segments_from_error,prev_segment)
          #               break
          #             end
          #           end
          #
          #           # cut off everything after error and replace last item with specfic error
          #           slice!(error_pos+1,size-error_pos)
          #           self[error_pos] = specific_error if specific_error
          self
        end

        def error_segment
          last if @complete && last.is_a?(::XYZ::LogSegmentError)
        end

        def has_error?
          # TODO: needs tp be written
          false
        end

        private

        # TODO: need to unify with self.log_complete?(lines) and run status info
        def complete?
          return false if empty?
          return true if last.line =~ /Finished catalog run/
          return true if last.line =~ /Puppet \(info\): \(end\)/
          return true if last.line =~ /Puppet \(debug\): Finishing transaction/
        end

        def find_error_position
          each_with_index { |seg, i| return i if seg.type == :error }
          nil
        end
      end

      class ErrorPuppetLog < ::XYZ::LogSegmentError
        def initialize(segments_from_error, prev_segment)
          super()
          parse!(segments_from_error, prev_segment)
        end
      end

      class ErrorGeneric < ErrorPuppetLog
        def self.isa?(_segments_from_error)
          true
        end

        private

        def parse!(_segments_from_error, _prev_segment)
          # TODO: need sto be written
          ##@error_detail = ...
        end
      end

      # order makes a differnce for parsing
      PossibleErrors = [ErrorGeneric]
    end
  end
end