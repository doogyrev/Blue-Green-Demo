#
# Cookbook Name:: drupal_server
# Recipe:: lsyncd_common
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#

# Lsync kernel tuning

execute 'increase max_user_watches for lsyncd for next reboot' do
  command 'cat >> /etc/sysctl.conf <<EOF

# Increase max_user_watches for lsyncd
fs.inotify.max_user_watches=32768
EOF'
  not_if { ::File.foreach('/etc/sysctl.conf').grep(/fs.inotify.max_user_watches=32768/).any? }
end

execute 'increase live max_user_watches for lsyncd' do
  command 'echo 32768 > /proc/sys/fs/inotify/max_user_watches'
  not_if { ::File.foreach('/proc/sys/fs/inotify/max_user_watches').grep(/32768/).any? }
end
