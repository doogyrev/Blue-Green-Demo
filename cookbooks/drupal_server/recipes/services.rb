#
# Cookbook Name:: drupal_server
# Recipe:: services
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#

service 'httpd' do
  action [:enable, :start]
end

service 'rsyslog' do
  supports :restart => true, :reload => true
  action [:enable, :start]
end

# service 'memcached' do
#	  action [:enable, :start]
# end

service 'lsyncd' do
  action [:enable]
end
