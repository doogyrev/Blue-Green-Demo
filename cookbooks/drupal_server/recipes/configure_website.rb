#
# Cookbook Name:: drupal_server
# Recipe:: configure_website
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#

remote_file '/etc/httpd/conf/httpd.conf' do
  source 'file:///root/web_config/httpd.conf'
  action :create
end

execute 'Replace env details' do
  command "sed -i '\
            s/MYSQL_HOST .*$/MYSQL_HOST \"#{node['drupal_server']['database_host']}\"/; \
            s/MYSQL_USER .*$/MYSQL_USER \"#{node['drupal_server']['database_site_user']}\"/; \
            s/MYSQL_PASSWD .*$/MYSQL_PASSWD \"#{node['drupal_server']['database_site_password']}\"/\
           ' /etc/httpd/conf/httpd.conf"
end

directory '/etc/httpd/conf/sites-enabled/' do
  owner 'root'
  group 'root'
  mode 0755
end

remote_file '/etc/httpd/conf/sites-enabled/bluegreen.conf' do
  source 'file:///root/web_config/bluegreen.conf'
  action :create
end

new_site = "`ls -dct #{node['drupal_server']['webroot']}/#{node['drupal_server']['install_dir']}-????-??-??_??:??:??|head -1`"
old_site = "`ls -dct #{node['drupal_server']['webroot']}/#{node['drupal_server']['install_dir']}-????-??-??_??:??:??|head -2|tail -1`"

#execute 'Copy settings.php' do
#  command "cp /root/web_config/settings.php \
#           #{ new_site }/sites/default/settings.php"
#end

execute 'Replace DB access details' do
  command "sed -i 's/drupal_db_user/#{node['drupal_server']['database_site_user']}/; \
            s/drupal_db_password/#{node['drupal_server']['database_site_password']}/; \
            s/drupal_db_host/#{node['drupal_server']['database_host']}/; \
	    s/drupal_db_name/#{node['drupal_server']['database_name']}/ \
           ' #{ new_site }/sites/default/settings.php"
end

#execute 'Replace Memcached details' do
#  command "sed -i 's/localhost:11211/#{node['drupal_server']['elasticache_cluster']}:11211/; \
#           ' #{ new_site }/sites/default/settings.php"
#end

#execute 'Copy .htaccess' do
#  command "cp /root/web_config/htaccess \
#           #{ new_site }/.htaccess"
#end

execute 'Fix permissions' do
  command "sed -i 's/sudo //g' /root/web_config/fix-permissions.sh && \
           cd #{ new_site } && \
           /root/web_config/fix-permissions.sh \
           #{ new_site } apache true"
end

#execute 'Link S3 files' do
#  command "ln -s /var/www/files/files-live/ #{ new_site }/sites/default/files"
#end

# execute "Put site into maintenance mode" do
#  command "cd #{node['drupal_server']['webroot']}/#{node['drupal_server']['install_dir']} && \
#           #{node[:drupal_server][:drush][:install_path]} vset maintenance_mode 1 --yes && \
#           #{node[:drupal_server][:drush][:install_path]} cc all"
#  only_if { ::File.exist?('#{node['drupal_server']['webroot']}/#{node['drupal_server']['install_dir']}/index.php') }
# end

execute 'Unlink current site' do
  command "unlink #{node['drupal_server']['webroot']}/#{node['drupal_server']['install_dir']}"
  only_if { ::File.symlink?("#{node['drupal_server']['webroot']}/#{node['drupal_server']['install_dir']}") }
end

execute 'Archive current site' do
  command "if [ #{ new_site } != #{ old_site } ]; then \
             /bin/tar cvfz #{ old_site }.tgz #{ old_site } && \
       /bin/rm -rf #{ old_site }; \
     fi"
end

execute 'Remove old archives' do
  command "find #{node['drupal_server']['webroot']}/* -maxdepth 0 \
           -type f -name '*.tgz' -exec ls -ctr {} \\;|head -n -1|xargs rm -f"
end

execute 'Make new site live' do
  command "ln -s #{ new_site } #{node['drupal_server']['webroot']}/#{node['drupal_server']['install_dir']}"
end

service 'httpd' do
  action [:enable, :restart]
end
