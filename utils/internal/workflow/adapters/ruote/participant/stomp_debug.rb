module DTK
  module StompDebug
    DEBUG_AGENT_RESPONSE = R8::Config[:debug][:arbiter]

    def inspect_agent_response(msg)
      if DEBUG_AGENT_RESPONSE
        Log.debug 'START: Debugging response from DTK Arbiter'
        Log.debug_pp msg
        Log.debug 'END: Debugging response from DTK Arbiter'
      end
    end
  end
end
