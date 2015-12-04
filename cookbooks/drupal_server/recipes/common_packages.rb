#
# Cookbook Name:: drupal_server
# Recipe:: common_packages
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#
##
# packages
##
package 'git'
package 'php54-gd'
package 'php54-process'
#package 'php54-pecl-apc'
package 'php54-xml'
package 'php54'
package 'php54-pecl-igbinary'
package 'php54-soap'
package 'php54-mysqlnd'
package 'php54-cli'
package 'php-pear'
package 'php54-devel'
package 'php54-mbstring'
package 'php54-common'
package 'php54-pecl-memcache'
package 'php54-pdo'
package 'php54-mcrypt'
package 'httpd24'
# package 'memcached'
yum_package 'lsyncd' do
  action :install
  options '--enablerepo=epel'
end
#package 'fuse'
#package 'fuse-devel'
#package 'fuse-libs'
#package 'libconfuse-devel'
#package 'libconfuse'
package 'gcc-c++'
package 'curl'
package 'libcurl-devel'
package 'libcurl'
package 'libxml2'
package 'libxml2-devel'
package 'openssl-devel'

newrelic_agent_php 'Install' do
  license 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
  app_name "Blue-Green-Demo #{node['drupal_server']['role']}"
  service_name 'httpd'
  config_file '/etc/php.d/newrelic.ini'
  logfile '/var/log/newrelic/php_agent.log'
end

execute 'NewRelic cfg file' do
  command 'cp /etc/newrelic/newrelic.cfg.template /etc/newrelic/newrelic.cfg'
  notifies 'restart', 'service[newrelic-daemon]', :delayed
  not_if { ::File.exist?('/etc/newrelic/newrelic.cfg') }
end

execute 'Increase PHP memory' do
  command "sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php.ini"
end

#execute 'Increase APC memory' do
#  command "sed -i 's/^apc.shm_size=.*M$/apc.shm_size=256M/' /etc/php.d/apc.ini"
#end
