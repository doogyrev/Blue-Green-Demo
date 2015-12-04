#
# Cookbook Name:: drupal_server
# Recipe:: slave
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'drupal_server::common_packages'

directory '/root/cron' do
  owner 'root'
  group 'root'
end

template '/root/cron/update_keys.sh' do
  source 'update_keys.sh.erb'
  mode 0700
end

template '/etc/cron.d/update_keys' do
  source 'update_keys'
end

include_recipe 'drupal_server::jenkins_user'

template '/usr/local/sbin/validate-rsync' do
  source 'validate-rsync'
  mode 0700
end

template '/etc/lsyncd.conf' do
  source 'slave_lsyncd.conf.erb'
end

include_recipe 'drupal_server::lsyncd_common'
include_recipe 'drupal_server::get_config'
include_recipe 'drupal_server::drush'
include_recipe 'drupal_server::rsyslog'
include_recipe 'drupal_server::services'

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

service 'newrelic-daemon' do
  action [:enable]
end

service 'lsyncd' do
  action [:enable, :start]
end
