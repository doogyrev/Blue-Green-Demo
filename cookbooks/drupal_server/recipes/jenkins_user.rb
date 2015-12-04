#
# Cookbook Name:: drupal_server
# Recipe:: jenkins_user
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#
user 'jenkins' do
  system true
  home '/home/jenkins'
  shell '/bin/bash'
  manage_home true
end

group 'apache' do
  action :modify
  members 'jenkins'
  append true
end

bash 'Add ec2-user key' do
  code <<-EOH
    mkdir -p /home/jenkins/.ssh && \
    cp -a /home/ec2-user/.ssh/authorized_keys /home/jenkins/.ssh/ && \
    chmod 700 /home/jenkins/.ssh && \
    chown -R jenkins. /home/jenkins/.ssh
  EOH
  creates '/home/jenkins/.ssh/authorized_keys'
end
