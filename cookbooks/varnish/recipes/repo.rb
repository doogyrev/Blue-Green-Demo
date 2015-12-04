#
# Cookbook Name:: varnish
# Recipe:: repo
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#

if node['platform_version'].to_i == 2013
  elversion = '6'
elsif node['platform_version'].to_i == 2014
  elversion = '6'
elsif node['platform_version'].to_i == 20
  elversion = '7'
elsif node['platform_version'].to_i == 21
  elversion = '7'
end

case node['platform']
when 'amazon'
  elversion = '6'
end

case node['platform_family']
when 'rhel', 'fedora'
  yum_repository 'varnish' do
    description "Varnish #{node['varnish']['version']} repo (#{node['platform_version']} - $basearch)"
    url "http://repo.varnish-cache.org/redhat/varnish-#{node['varnish']['version']}/el#{elversion}/$basearch/"
    gpgcheck false
    gpgkey 'http://repo.varnish-cache.org/debian/GPG-key.txt'
    action 'create'
  end
end
