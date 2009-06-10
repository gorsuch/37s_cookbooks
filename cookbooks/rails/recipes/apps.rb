if node[:role] == "app"
  require_recipe "passenger"
end

directory "/u/apps" do
  owner "app"
  group "app"
  mode 0755
  recursive true
end

directory "/u/logs" do
  action :create
  mode 0755
  owner "app"
  group "app"
end

directory "/u/logs/apps" do
  action :create
  mode 0775
  owner "app"
  group "www-data"
end

if node[:active_applications]

  # TODO: install the passenger app monitor which will kill any bloating processes
  # passenger_monitor "All apps" 

  node[:active_applications].each do |app, conf|
    full_name = "#{app}_#{conf[:env]}"
    filename = node[:role] == "web" ? "#{conf[:env]}_web.conf" : "#{conf[:env]}.conf"
    path = "/u/apps/#{app}/current/config/apache/#{filename}"
    
    if modules = node[:applications][app][:apache_modules]
      modules.each do |mod|
        require_recipe "apache2::mod_#{mod}"
        apache_module mod
      end      
    end

    if node[:applications][app][:gems]
      node[:applications][app][:gems].each do |g|
        if g.is_a? Array
          gem_package g.first do
            version g.last
          end
        else
          gem_package g
        end
      end
    end
    
    if node[:applications][app][:packages]
      node[:applications][app][:packages].each do |package_name|
        package package_name
      end      
    end
    
    if node[:applications][app][:symlinks]
      node[:applications][app][:symlinks].each do |target, source|
        link target do
          to source
        end
      end      
    end
    
    apache_site full_name do
      config_path path
      only_if { File.exists?("/etc/apache2/sites-available/#{full_name}") }
    end

    logrotate full_name do
      files "/u/apps/#{app}/current/log/*.log"
      frequency node[:role] == "web" ? "daily" : "weekly"
      restart_command "/etc/init.d/apache2 reload > /dev/null"
    end
  end
else
  Chef::Log.info "Add an :active_applications attribute to configure this node's apps"
end
