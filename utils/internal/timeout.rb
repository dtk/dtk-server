#Monkey patch for Timeout
module TimeoutMonkeyPatch
  module Timeout
    include ::Timeout
    def self.timeout(sec, klass = nil,&block)
      return TimerAdapterClass.timeout(sec,klass,&block) if TimerAdapterClass 

      return yield if sec == nil or sec.zero?
      raise ThreadError, "timeout within critical session" if Thread.critical
      exception = klass || Class.new(ExitException)

      begin
        x = Thread.current
        y = Thread.start {
          sleep sec
          pp [:time_out_triggered_for,x] if x.alive?
          x.raise exception, "execution expired" if x.alive?
        }
        pp [:time_thread,y,:current_thread,x]
        yield sec
        #    return true
      rescue exception => e
        rej = /\A#{Regexp.quote(__FILE__)}:#{__LINE__-4}\z/o
        (bt = e.backtrace).reject! {|m| rej =~ m}
        level = -caller(CALLER_OFFSET).size
        while THIS_FILE =~ bt[level]
          bt.delete_at(level)
          level += 1
        end
        raise if klass            # if exception class is specified, it
        # would be expected outside.
        raise Error, e.message, e.backtrace
      ensure
        pp [:time_out_triggered_not_neeeded_for,x] if y and y.alive?
        y.kill if y and y.alive?
      end
    end
    
    timer_adapter = nil
    #TODO: just treating system time adapter now
    if R8::Config[:timer]
      unless R8::Config[:timer][:type] == "system_timer"
        Log.error("only treating now system_timer adapter")
      else
        begin
          require 'system_timer'
          timer_adapter = SystemTimer
         rescue LoadError
          Log.error("cannot find system timer adapter; using default (Timeout)")
        end
      end
    end
    TimerAdapterClass = timer_adapter
  end
end

class MCollective::Client
#  include TimeoutMonkeyPatch
end


