#
# Cookbook Name:: drupal_server
# Recipe:: get_content
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#

execute 'Download Drupal website' do
  command "aws s3 --region eu-central-1 cp s3://#{node['drupal_server']['backup_location']}/#{node['drupal_server']['website_backup']} #{node['drupal_server']['webroot']}/"
end

execute 'Extract Drupal website' do
  command "cd #{node['drupal_server']['webroot']} && \
           tar xfj #{node['drupal_server']['website_backup']}"
end

execute 'Copy downloaded content to date-stamped copy' do
  command "cp -a #{node['drupal_server']['webroot']}/#{node['drupal_server']['website_download_dir']} \
           #{node['drupal_server']['webroot']}/#{node['drupal_server']['install_dir']}-`date +%F_%T`"
end
