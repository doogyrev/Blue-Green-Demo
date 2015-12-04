#
# Cookbook Name:: drupal_server
# Recipe:: rsyslog
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#

execute 'Add Drupal logging to rsyslog' do
  command 'cat > /etc/rsyslog.d/drupal.conf <<EOF
# Drupal logging
local0.*                                                /var/log/drupal.log
EOF'
  notifies 'restart', 'service[rsyslog]', :delayed
  not_if { ::File.exist?('/etc/rsyslog.d/drupal.conf') }
end
