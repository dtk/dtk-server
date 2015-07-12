require 'dtk_client'

class DtkClientAccessor
	attr_accessor :connection

	def initialize
		@connection = ::DTK::Client::Conn.new
	end

	def execute_command(context_name, entity_name, id, params=[], command_name)
		context_params = ::DTK::Shell::ContextParams.new(params)
		context_params.add_context_to_params(context_name, entity_name, id)
		response = ::DTK::Client::ContextRouter.routeTask(context_name, command_name, context_params, @connection)
	end
end