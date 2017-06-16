# = Class: apache
#
# Installs apache, ensures a few useful modules are installed (see
# apache_c2c::base), ensures that the service is running and the logs get rotated.
#
# By including subclasses where distro specific stuff is handled, it ensure that
# the apache class behaves the same way on diffrent distributions.
#
# == Parameters ===
#
# [*root*]
#   Root directory of vhosts, defaults to /var/www on Debian, /var/www/vhosts
#   on RedHat.
#
# [*service_ensure*]
#   Ensure value passed to the Apache service. Valid values are 'running'
#   (default), 'stopped', or 'unmanaged' (ensure is not set).
#
# [*service_enable*]
#   Enable value passed to the Apache service, defining the service's status
#   at boot. Valid values are true (default) and false.
#
# == Example ===
#
#   include apache
# test and test and more test

class apache_c2c (
  $root            = $apache_c2c::params::root,
  $service_ensure  = 'running',
  $service_enable  = true,
  $default_vhost   = true,
  $backend         = 'camptocamp',
) inherits ::apache_c2c::params {

  if ($::osfamily == 'Debian' and versioncmp($::operatingsystemmajrelease, '7') > 0)
    or ($::osfamily == 'RedHat' and versioncmp($::operatingsystemmajrelease, '6') > 0) {
    fail "Module 'apache_c2c' not compatible with this distro, use 'puppetlabs-apache' instead"
  }

  validate_absolute_path ($root)
  validate_re ($service_ensure, 'running|stopped|unmanaged')
  validate_bool ($service_enable)

  case $::osfamily {
    'Debian': { include ::apache_c2c::debian}
    'RedHat': { include ::apache_c2c::redhat}
    default: { fail "Unsupported osfamily ${::osfamily}" }
  }

  if $backend == 'puppetlabs' {
    if !defined(Class['apache']) {
      class { '::apache':
        default_mods      => false,
        keepalive         => 'On',
        keepalive_timeout => '5',
        mpm_module        => 'prefork',
        timeout           => '300',
        trace_enable      => 'Off',
      }
    }
  }
}
