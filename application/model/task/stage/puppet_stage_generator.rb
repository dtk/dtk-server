module XYZ
	module Stage
		# Amar: This class will generate part of the flow that enables multiple puppet calls
		# 		within one puppet_agent execution

		# 		First implementation will do this staging type only for node groups.
		# 		Components from one or more node groups will be extracted from list of all 
		# 		components into coresponding stages. Components from assembly instance will
		# 		be added as a last element of the group list. 
		# 
		# 		Later in the flow, for this group list, each group will be intra node stage,
		# 		based on which puppet manifest will be generated.
		#
		# 		TODO: Future implementation should allow user to manipulate component grouping...
		class PuppetStageGenerator
			def self.generate_stages(component_dependencies, state_change_list)
			 	cd_group = {}
			 	scl_group = {}
			 	cd_assembly = {}
			 	scl_assembly = [] 

			 	# Go through all components
			 	state_change_list.each do |sc|
			 		component_node_id = sc[:component][:node_node_id]
			 		# If node id and component's node_node_id are different, 
			 		# it means components comes from node group and not from assembly instance.
			 		# make puppet stages and return grouped results.
			 		unless sc[:node][:id] == component_node_id
			 			scl_group[component_node_id] ||= []
						scl_group[component_node_id] << sc
			 			cd_group[component_node_id] ||= {}
						cd_group[component_node_id][sc[:component][:id]] = component_dependencies[sc[:component][:id]]
					 else
						cd_assembly[sc[:component][:id]] = component_dependencies[sc[:component][:id]]
						scl_assembly << sc
			 		end
			 	end

			 	cd_ret = cd_group.values
			 	cd_ret << cd_assembly
			 	scl_ret = scl_group.values
			 	scl_ret << scl_assembly
			 	
			 	return cd_ret, scl_ret
			end
		end
	end
end
