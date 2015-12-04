#
# Cookbook Name:: varnish
# Recipe:: default
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'varnish::repo' if node['varnish']['use_default_repo']

package 'varnish'
package 'GeoIP-devel'

# Remove temp files from cron update scripts
file '/tmp/*_ips' do
  action :delete
end

template node['varnish']['default'] do
  source node['varnish']['conf_source']
  notifies :restart, 'service[varnish]', :delayed
end

file node['varnish']['secret_file'] do
  content "#{node['varnish']['secret_file_source']}\n"
  notifies :restart, 'service[varnish]', :delayed
end

template "#{node['varnish']['dir']}/#{node['varnish']['vcl_conf']}" do
  source node['varnish']['vcl_source']
  notifies :reload, 'service[varnish]', :delayed
  only_if { node['varnish']['vcl_generated'] == true }
end

service 'varnish' do
  supports [:restart => true, :reload => true]
  action :enable
end

service 'varnishlog' do
  supports [:restart => true, :reload => true]
  action node['varnish']['log_daemon'] ? [:enable, :start] : [:disable, :stop]
end

directory '/root/cron' do
  owner 'root'
  group 'root'
end

template "#{node['varnish']['dir']}/backends.vcl" do
  source 'backends.vcl'
  not_if { ::File.exist?("#{node['varnish']['dir']}/backends.vcl") }
end

template "#{node['varnish']['dir']}/access.vcl" do
  source 'access.vcl'
  not_if { ::File.exist?("#{node['varnish']['dir']}/access.vcl") }
end

template '/root/cron/update_backends.sh' do
  source 'update_backends.sh'
  mode 0700
end

template '/etc/cron.d/update_backends' do
  source 'update_backends'
end
