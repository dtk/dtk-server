module DTK
  module McollectiveDebug
    DEBUG_AGENT_RESPONSE = R8::Config[:debug][:mcollective]

    def inspect_agent_response(msg)
      if DEBUG_AGENT_RESPONSE
        Log.info 'START: Debugging response from Mcollective'
        Log.info_pp msg
        Log.info 'END: Debugging response from Mcollective'
      end
    end
  end
end
