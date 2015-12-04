name 'varnish'
maintainer 'MySysAdmin Ltd'
maintainer_email 'david@mysysadmin.co.uk'
license 'All rights reserved'
description 'Installs/Configures varnish'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '2.1.5'

depends 'build-essential', '>= 0.0.0'
depends 'yum', '~> 3.0'
depends 'yum-epel', '>= 0.0.0'
