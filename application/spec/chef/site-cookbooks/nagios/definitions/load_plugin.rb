define :load_plugin, :action => :execute do
  (params[:required_gem_packages]||[]).each do |p|
    gem_package p do
      action :install
    end
  end
  ([params[:name]]+(params[:required_support_files]||[])).each do |file|
    if ::Chef::VERSION.to_f >= 0.9
      cookbook_file "/usr/lib/nagios/plugins/#{file}" do
        source "plugins/#{file}"
        owner "nagios"
        group "nagios"
        mode 0755
      end
    else
      remote_file "/usr/lib/nagios/plugins/#{file}" do
        source "plugins/#{file}"
        owner "nagios"
        group "nagios"
        mode 0755
      end
    end
  end
  if params[:attributes_file] and params[:attributes_to_monitor]
    attributes_file = "/usr/lib/nagios/plugins/#{params[:attributes_file]}"
    directory File.dirname(attributes_file) do 
      mode 0755
      owner "nagios"
      group "nagios"
      recursive true
    end
    template attributes_file do
      source "attributes_file.erb"
      mode 0600
      owner "nagios"
      group "nagios"
      variables :attributes => params[:attributes_to_monitor]
    end
  end
end


