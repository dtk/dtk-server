require 'timeout'
require 'open3'

module Arbiter
  module Common
    module Open3

      STREAM_TIMEOUT  = 5

      # Running puppet directly on system and from ruby process has proven different. Following is set of environment variables
      # that assures proper execution from bundler / rvm ruby
      AGNOSTIC_PUPPET_VARS = {
         "BUNDLE_GEMFILE" => nil,
         "BUNDLE_BIN_PATH" => nil,
         "RUBYOPT" => nil,
         "rvm_" => nil,
         "RACK_ENV" => nil,
         "RAILS_ENV" => nil
       }

      ##
      # Open3 method extended with timeout, more info https://gist.github.com/pasela/9392115
      #

      def capture3_with_timeout(*cmd)
        spawn_opts = Hash === cmd.last ? cmd.pop.dup : {}
        opts = {
          :stdin_data => "",
          :timeout    => @timeout || 0,
          :signal     => :TERM,
          :kill_after => nil,
        }

        in_r,  in_w  = IO.pipe
        out_r, out_w = IO.pipe
        err_r, err_w = IO.pipe
        in_w.sync = true

        spawn_opts[:in]  = in_r
        spawn_opts[:out] = out_w
        spawn_opts[:err] = err_w

        result = {
          :pid     => nil,
          :status  => nil,
          :stdout  => nil,
          :stderr  => nil,
          :timeout => false,
        }

        out_reader = nil
        err_reader = nil
        wait_thr = nil

        begin
          Timeout.timeout(opts[:timeout]) do
            result[:pid] = spawn(AGNOSTIC_PUPPET_VARS, *cmd, spawn_opts)
            wait_thr = Process.detach(result[:pid])
            in_r.close
            out_w.close
            err_w.close

            out_reader = Thread.new { out_r.read }
            err_reader = Thread.new { err_r.read }

            in_w.close

            result[:status] = wait_thr.value
          end
        rescue Timeout::Error
          result[:timeout] = true
          pid = result[:pid]
          Process.kill(opts[:signal], pid)
          if opts[:kill_after]
            unless wait_thr.join(opts[:kill_after])
              Process.kill(:KILL, pid)
            end
          end
        ensure
          result[:status] = wait_thr.value if wait_thr
          begin
            # there is a bug where there is infinite leg on out_reader (e.g. hohup) commands
            Timeout.timeout(STREAM_TIMEOUT) do
              result[:stdout] = out_reader.value if out_reader
              result[:stderr] = err_reader.value if err_reader
            end
          rescue Timeout::Error
            result[:stdout] ||= ''
            result[:stderr] ||= ''
          end
          out_r.close unless out_r.closed?
          err_r.close unless err_r.closed?
        end

        result[:stdout] = result[:stdout].gsub(/\e\[([;\d]+)?m/, '') if result[:stdout]
        result[:stderr] = result[:stderr].gsub(/\e\[([;\d]+)?m/, '') if result[:stderr]

        [result[:stdout], result[:stderr], result[:status], result]
      end

    end
  end
end