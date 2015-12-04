#
# Cookbook Name:: drupal_server
# Recipe:: get_config
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#

directory 'web_config' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

execute 'Download vhost conf' do
  command "aws s3 --region eu-central-1 cp s3://uk.co.mysysadmin.config/bluegreen.conf /root/web_config/"
end

execute 'Download apache conf' do
  command "aws s3 --region eu-central-1 cp s3://uk.co.mysysadmin.config/httpd.conf /root/web_config/"
end

#execute 'Download Drupal conf' do
#  command "aws s3 --region eu-central-1 cp s3://uk.co.mysysadmin.config/settings.php /root/web_config/"
#end

#execute 'Download htaccess' do
#  command "aws s3 --region eu-central-1 cp s3://uk.co.mysysadmin.config/htaccess /root/web_config/"
#end

execute 'Download fix permissions script' do
  command "aws s3 --region eu-central-1 cp s3://uk.co.mysysadmin.config/fix-permissions.sh /root/web_config/ &&\
           chmod +x /root/web_config/fix-permissions.sh"
end
