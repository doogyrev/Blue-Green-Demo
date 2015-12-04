default['varnish']['default'] = '/etc/sysconfig/varnish'
default['varnish']['version'] = '3.0'
default['varnish']['dir'] = '/etc/varnish'
default['varnish']['start'] = 'yes'
default['varnish']['vcl_conf'] = 'default.vcl'
default['varnish']['vcl_source'] = 'default.vcl.erb'
default['varnish']['vcl_generated'] = true
default['varnish']['conf_source'] = 'default.erb'
default['varnish']['conf_cookbook'] = 'varnish'
default['varnish']['secret_file'] = '/etc/varnish/secret'
default['varnish']['secret_file_source'] = '6ae09c881b888e0c879ba71d5661c9b4"
default['varnish']['log_daemon'] = true
default['varnish']['use_default_repo'] = true

# default['varnish']['backend_host'] = `aws ec2 describe-tags  --region eu-central-1 --filters Name=resource-type,Values=instance  --filters Name=resource-id,Values="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"|grep ELB-DRUPAL|cut -d '"' -f 4`
# default['varnish']['backend_port'] = '80'
