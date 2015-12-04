#
# Cookbook Name:: drupal_server
# Recipe:: cdn
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#

execute 'CDN config' do
  command "cd #{node['drupal_server']['webroot']}/#{node['drupal_server']['install_dir']} && \
           current_config=`#{node['drupal_server']['drush']['install_path']} vget cdn_basic_mapping|awk '{ print $2 }'` && \
           if [ $current_config != #{node['drupal_server']['cdn_basic_mapping']} ]; then
             #{node['drupal_server']['drush']['install_path']} vset cdn_basic_mapping #{node['drupal_server']['cdn_basic_mapping']} && \
       #{node['drupal_server']['drush']['install_path']} cc all;
     fi"
end
