#
# Cookbook Name:: drupal_server
# Recipe:: drush
#
# Copyright 2015, MySysAdmin Ltd
#
# All rights reserved - Do Not Redistribute
#

# Install Drush

script 'install_composer' do
  interpreter 'bash'
  user node['composer']['user']
  cwd '/tmp'
  code <<-EOH
  curl -s https://getcomposer.org/installer| php -- --install-dir="#{node['composer']['install_dir']}"
  mv #{node['composer']['install_dir']}/composer.phar #{node['composer']['install_dir']}/composer
  ln -s #{node['composer']['install_dir']}/composer /usr/bin/composer
  EOH
  not_if { ::File.exist?('/usr/bin/composer') }
end

# composer_home = ::File.expand_path("~#{ node['drupal_server']['drush']['user'] }/.composer")
# composer_drush_path = "#{ composer_home }/vendor/bin/drush"

# drush_version = node['drupal_server']['drush']['version'] == '7.x' ? 'dev-master' : node['drupal_server']['drush']['version']

script 'install_drush' do
  interpreter 'bash'
  user node['composer']['user']
  cwd '/tmp'
  code <<-EOH
  mkdir #{node['composer']['home']}
  cd #{node['composer']['home']}
  export COMPOSER_HOME=#{node['composer']['home']}
  composer global require drush/drush:#{node['drupal_server']['drush']['version']}
  ln -s #{node['composer']['home']}/vendor/bin/drush #{node['drupal_server']['drush']['install_path']}
  EOH
  not_if { ::File.exist?(node['drupal_server']['drush']['install_path']) }
end

# execute 'drupal-make-drush-install' do
#  creates composer_drush_path
#  command "composer global require drush/drush:#{ drush_version }"
#  user node['drupal_server']['drush']['user']
#  group node['drupal_server']['drush']['group']
#  environment(
#    'COMPOSER_HOME' => composer_home
#  )
# end
#
# link node['drupal_server']['drush']['install_path'] do
#  to composer_drush_path
#  owner node['drupal_server']['drush']['user']
# end
