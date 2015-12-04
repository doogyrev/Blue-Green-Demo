default['drupal_server']['webroot'] = '/var/www/html'
default['drupal_server']['install_dir'] = 'livesite'
default['drupal_server']['website_download_dir'] = 'livesite-download'
default['drupal_server']['website_backup'] = 'livesite-download.tbz2'
default['drupal_server']['setup_site_database'] = true
default['drupal_server']['database_host'] = `tr -d "\n" < /etc/chef/RDS_DB`
default['drupal_server']['database_port'] = 3306
default['drupal_server']['database_name'] = 'drupal_db'
default['drupal_server']['database_site_user'] = 'drupal_db_user'
default['drupal_server']['database_site_password'] = `tr -d "\n" < /root/.dp.pw`
default['drupal_server']['backup_location'] = 'uk.co.mysysadmin.backups'
default['drupal_server']['database_backup'] = `aws s3 ls --region eu-central-1 s3://uk.co.mysysadmin.backups/db/ |grep sql.bz2$|awk '{ print $4 }'|sort|tail -1|tr -d "\n"`
default['drupal_server']['rds_master_password'] = `tr -d "\n" < /root/.my.pw`
default['drupal_server']['elasticache_cluster'] = `tr -d "\n" < /etc/chef/EC_CLUSTER`
default['drupal_server']['stack'] = `tr -d "\n" < /etc/chef_environment`
default['drupal_server']['role'] = `tr -d "\n" < /etc/chef_role`
default['drupal_server']['cdn_basic_mapping'] = 'http://xxxxxxxxxx.cloudfront.net|.css .js .png .jpg .jpeg .gif .ico .pdf .svg'
default['drupal_server']['secretpath'] = '/etc/chef/encrypted_data_bag_secret'
default['drupal_server']['office_ip_1'] = '10.20.30.40'
default['drupal_server']['office_ip_2'] = '50.60.70.80'
default['drupal_server']['nat_ip_1'] = '52.29.169.97'
default['drupal_server']['nat_ip_2'] = '52.29.169.196'

default['varnish']['secret_file_source'] = '6ae09c881b888e0c879ba71d5661c9b4'

default['composer']['install_dir']  = '/usr/local/bin'
default['composer']['user'] = 'root'
#default['composer']['home'] = '/usr/local/composer'
default['composer']['home'] = '/var/www/html/composer'

default['drupal_server']['drush'] = {
  :user => 'root',
  :group => 'root',
  :version => '7.x',
  :install_path => '/usr/bin/drush'
}
