#
# Cookbook Name:: drupal_server
# Recipe:: staging
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#

template "#{node['drupal_server']['webroot']}/#{node['drupal_server']['install_dir']}/robots.txt" do
  source 'staging_robots.txt'
  mode 0640
end

bash 'Allow access only from office IPs' do
  code <<-EOH
    cat >> #{node['drupal_server']['webroot']}/#{node['drupal_server']['install_dir']}/.htaccess << EOF

SetEnvIF X-Forwarded-For "#{node['drupal_server']['office_ip_1']}" AllowIP
SetEnvIF X-Forwarded-For "#{node['drupal_server']['office_ip_2']}" AllowIP
SetEnvIF X-Forwarded-For "#{node['drupal_server']['nat_ip_1']}" AllowIP
SetEnvIF X-Forwarded-For "#{node['drupal_server']['nat_ip_2']}" AllowIP

<RequireAny>
  Require env AllowIP
</RequireAny>
EOF
  EOH
  not_if { ::File.foreach("#{node['drupal_server']['webroot']}/#{node['drupal_server']['install_dir']}/.htaccess").grep(/#{node['drupal_server']['office_ip_1']}/).any? }
end

bash 'Comment out cookie_domain in settings.php' do
  code <<-EOH
    sed -i 's/^\$cookie_domain/\#\$cookie_domain/g' #{node['drupal_server']['webroot']}/#{node['drupal_server']['install_dir']}/sites/default/settings.php
  EOH
end

template '/etc/httpd/conf.d/welcome.conf' do
  source 'welcome.conf'
  mode 0644
  notifies 'restart', 'service[httpd]', :delayed
end

template '/root/cron/update_varnish_nodes.sh' do
  source 'update_varnish_nodes.sh_staging.erb'
  mode '0700'
end

execute 'Change New Relic app name to "staging"' do
  command "sed -i 's/^newrelic.appname.*$/newrelic.appname = \"Blue-Green-Demo Website staging\"/' /etc/php.d/newrelic.ini"
end
