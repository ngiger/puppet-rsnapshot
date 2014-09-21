#
# Copyright (C) 2013 Loic Dachary <loic@dachary.org>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#
# == Class: rsnapshot::puppetmaster
#
# Create the ssh key to be used by rsnapshot to backup a machine. It
# must be part of the puppet master manifest definition.
#
# === Example
#
# node 'puppetmaster.domain.com' {
#   class { 'rsnapshot::puppetmaster': }
# }
#
class rsnapshot::puppetmaster {
  file {
    '/etc/puppet/modules/rsnapshot/files':
      ensure                    => directory, mode => '0700',
      owner                     => puppet, group    => nogroup,
  }

  exec { 'create_key':
    command => '/usr/bin/ssh-keygen -N "" -f /etc/puppet/modules/rsnapshot/files/rsnapshot_key ; chown puppet /etc/puppet/modules/rsnapshot/files/rsnapshot_key*',
    creates => '/etc/puppet/modules/rsnapshot/files/rsnapshot_key',
    require => File['/etc/puppet/modules/rsnapshot/files'],
  }
}

#
# == Class: rsnapshot::nagios
#
# Install a nagios plugin that checks the sanity of the rsnapshot
# backups. It is designed to run on the machine hosting the backup and
# should be called by nrpe or mrpe.
#
# === Example
#
# node 'nagios.domain.com' {
#   class { 'rsnapshot::nagios': }
# }
#
class rsnapshot::nagios {
  file {
    '/usr/lib/nagios':
      ensure => directory, mode => '0755',
      owner => root, group => root;
    '/usr/lib/nagios/plugins':
      ensure => directory, mode => '0755',
      owner => root, group => root;
    '/usr/lib/nagios/plugins/check_rsnapshot':
      ensure => present, mode => '0555',
      owner => root, group => root,
      source => 'puppet:///rsnapshot/check_rsnapshot';
  }
}

#
# == Class: rsnapshot::server
#
# Creates one rsnapshot configuration file for each machine for which
# backup has been required by including rsnapshot::client in the
# puppet manifest. A crontab is installed to run each configuration
# file in sequence, daily, weekly and monthly. The logs are stored
# in /var/log/rsnapshot.
#
# === Parameters
#
# [*ip*]
#   A comma separated list of the ip addresses of the rsnapshot server.
#   The machines to backup will use this list to restrict the incoming ssh
#   connections (defaults to *$::ipaddress*).
#
# === Example
#
# node 'machineA.domain.com' {
#   class { 'rsnapshot::client': }
# }
#
# node 'machineB.domain.com' {
#   class { 'rsnapshot::client': }
# }
#
# node 'rsnapshot.domain.com' {
#   class { 'rsnapshot::server': }
# }
#
# Create one rsnapshot configuration file for *machineA.domain.com* and
# *machineB.domain.com*.
#
# *machineA.domain.com* will accept rsync over ssh from rsnapshot.domain.com
# default ip address ( *$::ipaddress* ).
# 
#
class rsnapshot::server (
  $ip = $::ipaddress,
  ) {
  package { 'rsnapshot':
    ensure => installed
  }

  file { '/etc/logrotate.d/rsnapshot':
    ensure                  => present, mode => '0444',
    owner                   => root, group    => root,
    source                  => 'puppet:///rsnapshot/logrotate.d/rsnapshot',
    require                 => Package['rsnapshot'],
  }

  file { '/etc/cron.d/rsnapshot':
    ensure                  => present, mode => '0444',
    owner                   => root, group    => root,
    source                  => 'puppet:///rsnapshot/cron.d/rsnapshot',
    require                 => Package['rsnapshot'],
  }

  file { '/root/.ssh/rsnapshot_key':
    ensure => present, mode => '0400',
    owner => root, group => root,
    source => 'puppet:///rsnapshot/rsnapshot_key';
  }

  $public_key = file('/etc/puppet/modules/rsnapshot/files/rsnapshot_key.pub')
  
  @@file_line { 'rsnapshot_public_key':
    ensure => present,
    path   => '/root/.ssh/authorized_keys',
    line   => "from=\"127.0.0.1,${ip}\",command=\"echo \\\"\$SSH_ORIGINAL_COMMAND\\\" | grep --quiet '^rsync --server --sender' && ionice -c3 \$SSH_ORIGINAL_COMMAND\" ${public_key}",
    tag    => 'rsnapshot',
  }

  File <<| tag == 'rsnapshot' |>>

  file {
    '/var/run/rsnapshot/':
      ensure => directory,
      mode => '0755', owner => root, group => root;
    '/var/log/rsnapshot/':
      ensure => directory,
      mode => '0755', owner => root, group => root;
  }
}

#
# == Class: rsnapshot::client
#
# Create a rsnapshot configuration file to be used by the machine running
# rsnapshot. It is based on a template and exported to the puppet master.
# It will install the ssh key of each rsnapshot server known to the puppet
# master to give them the necessary access to perform the backups.
#
# === Parameters
#
# [*ip*]
#   The ip address ( or hostname ) that the rsnapshot machine must use
#   to get access to the machine. (defaults to *$::fqdn*).
#
# [*excludes*]
#   An array of strings used to compose the *--exclude* arguments of
#   the rsync command. (defaults to []).
#
# === Variables
#
# [*$::fqdn*]
#   Is used as a name for the configuration file and within the
#   configuration file itself to create unique files for logs etc.
#
# === Example
#
# node 'debian.novalocal' {
#  class { 'rsnapshot::client':
#    ip => $::ipaddress,
#    excludes => [ '/media/debian', '/backup' ],
# }
#
# Because the *$::fqdn* of *debian.novalocal* does not resolve in the context
# of the machine running rsnapshot, it is replaced by the ip address of the
# machine. The */media/debian* and */backup* directory on *debian.novalocal*
# must not be included in the backup. The *excludes* argument will translate
# into *--exlude=/media/debian* *--exclude=/backup* on the rsync command line.
# 
class rsnapshot::client (
  $excludes = [],
  $ip = $::fqdn,
  ) {

  if ! defined(Package['rsync']) {
    package { 'rsync': ensure => installed }
  }
    
  File_line <<| tag == 'rsnapshot' |>>

  @@file { "/var/cache/rsnapshot/${::fqdn}.conf":
    ensure                               => present,
    mode                                 => '0444', owner                => root, group => root,
    content                              => template('rsnapshot/rsnapshot.conf.erb'),
    require                              => Package['rsnapshot'],
    tag                                  => 'rsnapshot',
  }
}
