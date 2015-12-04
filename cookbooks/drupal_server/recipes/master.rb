#
# Cookbook Name:: drupal_server
# Recipe:: master
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#
##
# packages
##
include_recipe 'drupal_server::common_packages'

package 'lua'
package 'lua-devel'
package 'pkgconfig'
package 'gcc'
package 'asciidoc'

# Remove temp files from cron update scripts
file '/tmp/*_ids' do
  action :delete
end

directory '/root/cron' do
  owner 'root'
  group 'root'
end

# Setup database
include_recipe 'drupal_server::database'

# Install Drush
include_recipe 'drupal_server::drush'

# Get site content and configure
include_recipe 'drupal_server::jenkins_user'
include_recipe 'drupal_server::get_content'
include_recipe 'drupal_server::get_config'
include_recipe 'drupal_server::configure_website'

# Configure Drupal for Varnish
include_recipe 'drupal_server::varnish'

# Setup Lsync
include_recipe 'drupal_server::lsyncd_common'

execute 'create-ssh-key-root' do
  command 'ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa'
  not_if { ::File.exist?('/root/.ssh/id_rsa') }
end

# NB - this will overwrite any existing key - latest master is THE master...
execute 'upload-public-ssh-key' do
  command "aws s3 --region eu-central-1 cp /root/.ssh/id_rsa.pub \
           s3://uk.co.mysysadmin.chef-credentials/#{node['drupal_server']['stack']}-drupal_master_pub_key"
end

template '/root/cron/update_lsyncd.sh' do
  source 'update_lsyncd.sh.erb'
  mode 0700
end

template '/etc/cron.d/update_lsyncd' do
  source 'update_lsyncd'
  mode 0644
end

# Add Drupal logging
include_recipe 'drupal_server::rsyslog'

# Install New Relic
newrelic_agent_php 'Install' do
  license 'adbe8f7de8329733828e38a65a49fdad5e2c48d0'
  app_name "Blue-Green-Demo Website live"
  service_name 'httpd'
  config_file '/etc/php.d/newrelic.ini'
  logfile '/var/log/newrelic/php_agent.log'
end

execute 'NewRelic cfg file' do
  command 'cp /etc/newrelic/newrelic.cfg.template /etc/newrelic/newrelic.cfg'
  notifies 'restart', 'service[newrelic-daemon]', :delayed
  not_if { ::File.exist?('/etc/newrelic/newrelic.cfg') }
end

# Configure services
include_recipe 'drupal_server::services'

# Start NewRelic
service 'newrelic-daemon' do
  action [:enable, :start]
end
