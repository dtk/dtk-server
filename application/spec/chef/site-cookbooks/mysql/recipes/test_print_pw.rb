include_recipe "associations"
params = XYZ::Associations.get_params(cookbook_name,recipe_name,node)
Chef::Log.info("here: params = #{params.inspect}")

