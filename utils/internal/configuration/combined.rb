#This variables need to be set after both defaults and user oevrrides are given
R8::Config[:base_uri] = "http://#{R8::Config[:server_public_dns]}:#{R8::Config[:server_port].to_s}"

#Application paths.., these should be set/written by templating engine on every call
R8::Config[:base_js_uri] = "#{R8::Config[:base_uri]}/js"
R8::Config[:base_js_cache_uri] = "#{R8::Config[:base_uri]}/js/cache"
R8::Config[:base_css_uri] = "#{R8::Config[:base_uri]}/css"
R8::Config[:base_images_uri] = "#{R8::Config[:base_uri]}/images"
R8::Config[:node_images_uri] = "#{R8::Config[:base_uri]}/images/nodeIcons"
R8::Config[:component_images_uri] = "#{R8::Config[:base_uri]}/images/componentIcons"
R8::Config[:avatar_base_uri] = "#{R8::Config[:base_uri]}/images/user_avatars"
R8::Config[:git_user_home] = "/home/#{R8::Config[:repo][:git][:server_username]}"
