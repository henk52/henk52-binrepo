# Class: binrepo
# ===========================
#
# Full description of class binrepo here.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'binrepo':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Author Name <author@domain.com>
#
# Copyright
# ---------
#
# Copyright 2016 Your name here, unless otherwise noted.
#
class binrepo (
 $arRepoAdmPublicKeys = hiera('repoadmpubkeys'),
 $szRepoWebHostAddr = hiera('RepoWebHostAddr', '0.0.0.0')
){

$szArtifactPath = '/var/artifacts'
$szVirtualMachinePath = '/var/virtualmachines'

user { 'repoadm':
  ensure     => present,
  home       => '/home/repoadm',
  managehome => true,
}

file { "$szArtifactPath":
  ensure => directory,
  owner  => 'repoadm',
  require => User['repoadm'],
}

file { "$szVirtualMachinePath":
  ensure => directory,
  owner  => 'repoadm',
  require => User['repoadm'],
}

# hosts auth keys.
file { '/home/repoadm/.ssh':
  ensure  => directory,
  owner   => 'repoadm',
  mode    => '700',
  require => User['repoadm'],
}

file { '/home/repoadm/.ssh/authorized_keys':
  ensure  => file,
  owner   => 'repoadm',
  mode    => '700',
  content => inline_template("<% @arRepoAdmPublicKeys.each do |szKey| -%>
<%= szKey %>
<% end %>"),
  require => File['/home/repoadm/.ssh'],
}

$arAliases = [
  {
    alias => '/artifacts',
    path  => "$szArtifactPath",
  },
  {
    alias => '/virtualmachines',
    path  => "$szVirtualMachinePath",
  },
]

exec { 'temporarily_set_selinux_permisive':
  command => 'setenforce 0',
  onlyif  => 'sestatus | grep mode  | grep -q enforcing',
  path    => ['/usr/sbin','/usr/bin'],
}

# Base class. Turn off the default vhosts; we will be declaring
# all vhosts below.
class { 'apache':
  default_vhost => false,
  require       => Exec['temporarily_set_selinux_permisive'],
}



# TODO C Move the 'directories' directive from a harcode,
#  to a configurable thing.
apache::vhost { 'subdomain.example.com':
  ensure         => present,
  ip             => "${szRepoWebHostAddr}",
  ip_based       => true,
  port           => '80',
  docroot        => '/var/www/subdomain',
  aliases        => $arAliases,
  directoryindex => 'disabled',
  options        => [ '+Indexes' ],
  directories => [
    { path => "$szArtifactPath", options => [ '+Indexes' ], },
    { path => "$szVirtualMachinePath", options => [ '+Indexes' ], },
  ],
}


} # end class.
