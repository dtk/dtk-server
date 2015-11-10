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

	def execute_clone_command(context_name, entity_name, id, params=[],version)
		context_params = ::DTK::Shell::ContextParams.new(params)
		context_params.forward_options("version" => version)
		context_params.add_context_to_params(context_name, entity_name, id)
		response = ::DTK::Client::ContextRouter.routeTask(context_name, 'clone', context_params, @connection)
	end

	def execute_command_with_options(context_name, entity_name, id, command, options, params=[])
		context_params = ::DTK::Shell::ContextParams.new(params)
		options.each do |key, value|
			puts key, value
			context_params.forward_options(key.to_s => value.to_s)
		end
		context_params.add_context_to_params(context_name, entity_name, id)
		response = ::DTK::Client::ContextRouter.routeTask(context_name, command, context_params, @connection)
	end
end