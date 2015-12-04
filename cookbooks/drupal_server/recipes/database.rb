#
# Cookbook Name:: drupal_server
# Recipe:: database
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#

# Setup database

mysql2_chef_gem 'default' do
  action :install
end

if node['drupal_server']['setup_site_database'] == true

  mysql_connection_info = {
    :host     => node['drupal_server']['database_host'],
    :username => 'master',
    :password => node['drupal_server']['rds_master_password']
  }

  mysql_database node['drupal_server']['database_name'] do
    connection mysql_connection_info
    action [:create]
  end

  mysql_database_user node['drupal_server']['database_site_user'] do
    connection mysql_connection_info
    password node['drupal_server']['database_site_password']
    host '10.100.%'
    database_name node['drupal_server']['database_name']
    privileges ['SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES']
    action [:create, :grant]
  end

  execute 'get DB backup from S3' do
    command "aws s3 --region eu-central-1 cp s3://#{node['drupal_server']['backup_location']}/db/#{node['drupal_server']['database_backup']} /root/"
    creates "/root/#{node['drupal_server']['database_backup']}"
  end

  execute 'Populating Database' do
    command "bzcat /root/#{node['drupal_server']['database_backup']} | \
             mysql -h #{node['drupal_server']['database_host']} \
             -u #{node['drupal_server']['database_site_user']} \
             -p#{node['drupal_server']['database_site_password']} \
             #{node['drupal_server']['database_name']} && \
             touch /root/.DB_populated"
    creates '/root/.DB_populated'
  end
end
