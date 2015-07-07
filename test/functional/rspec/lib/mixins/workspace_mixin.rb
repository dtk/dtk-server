module WorkspaceMixin
	def get_workspace_id
		response = send_request('/rest/assembly/list_with_workspace', {})
		workspace = response['data'].find { |x| x['display_name'] == "workspace"}['id']
		return workspace
	end

	def purge_content(service_id)
		puts "Purge content:", "--------------"
		content_purged = false

		response = send_request('/rest/assembly/purge', assembly_id: service_id)
		if response['status'].include? "ok"
			puts "Content has been purged successfully!"
			content_purged = true
		else
			puts "Content has not been purged successfully!"
		end
		puts ""
		return content_purged
	end
end