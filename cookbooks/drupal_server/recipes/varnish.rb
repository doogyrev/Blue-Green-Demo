#
# Cookbook Name:: drupal_server
# Recipe:: varnish
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#

execute 'Add Varnish secret' do
  command "cd #{node['drupal_server']['webroot']}/#{node['drupal_server']['install_dir']} && \
           current_key=`#{node['drupal_server']['drush']['install_path']} vget varnish_control_key|awk '{ print $2 }'` && \
           if [ $current_key != #{node['varnish']['secret_file_source']} ]; then
             #{node['drupal_server']['drush']['install_path']} vset varnish_control_key #{node['varnish']['secret_file_source']} && \
       #{node['drupal_server']['drush']['install_path']} cc all;
     fi"
end

template '/root/cron/update_varnish_nodes.sh' do
  source 'update_varnish_nodes.sh.erb'
  mode '0700'
end

template '/etc/cron.d/update_varnish_nodes' do
  source 'update_varnish_nodes'
end
