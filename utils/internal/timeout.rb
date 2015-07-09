# Monkey patch for Timeout
require 'timeout'
module TimeoutMonkeyPatch
  module Timeout
    include ::Timeout
    def self.timeout(sec, klass = nil, &block)
      return TimerAdapterClass.timeout(sec, klass, &block) if TimerAdapterClass

      return yield if sec.nil? or sec.zero?
      fail ThreadError, 'timeout within critical session' if Thread.critical
      exception = klass || Class.new(ExitException)

      begin
        x = Thread.current
        debug_print(:timeout_info, { timeout: sec, current_thread: x })
        y = Thread.start {
          sleep sec
          x.raise exception, 'execution expired' if x.alive?
        }
        yield sec
        #    return true
      rescue exception => e
        debug_print(:time_out_triggered_for, x)
        rej = /\A#{Regexp.quote(__FILE__)}:#{__LINE__ - 4}\z/o
        (bt = e.backtrace).reject! { |m| rej =~ m }
        level = -caller(CALLER_OFFSET).size
        while THIS_FILE =~ bt[level]
          bt.delete_at(level)
          level += 1
        end
        raise if klass            # if exception class is specified, it
        # would be expected outside.
        raise Error, e.message, e.backtrace
      ensure
        y.kill if y and y.alive?
      end
      debug_print(:time_out_not_needed_for, x)
    end

    Lock = Mutex.new
    def self.debug_print(tag, msg)
      Lock.synchronize { pp [tag, msg] }
    end

    timer_adapter = nil
    # TODO: just treating system time adapter now
    if R8::Config[:timer]
      case (R8::Config[:timer][:type])
       when 'system_timer'
        begin
          require 'system_timer'
          timer_adapter = SystemTimer
         rescue LoadError
          Log.error('cannot find system timer adapter; using default (Timeout)')
        end
       when 'debug_timeout'
        timer_adapter = nil
       else
        Log.error('only treating now system_timer adapter')
      end
    end
    TimerAdapterClass = timer_adapter
  end
end
# TODO: if enable need to conditiuonally add require 'mcollective'
if (R8::Config[:timer] || {})[:type]
  class MCollective::Client
    include TimeoutMonkeyPatch
  end
end
