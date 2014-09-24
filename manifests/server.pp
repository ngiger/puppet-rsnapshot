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

class rsnapshot::server (
  $ip = $::ipaddress,
  $public_key = [], # file('/etc/puppet/modules/rsnapshot/files/rsnapshot_key.pub')
  ) {
  package { 'rsnapshot':
    ensure => installed
  }

  file { '/etc/logrotate.d/rsnapshot':
    ensure  => present,
    mode    => '0444',
    owner   => root,
    group   => root,
    source  => 'puppet:///modules/rsnapshot/logrotate.d/rsnapshot',
    require => Package['rsnapshot'],
  }

  file { '/etc/cron.d/rsnapshot':
    ensure  => present,
    mode    => '0444',
    owner   => root,
    group   => root,
    content => template('rsnapshot/cron.d/rsnapshot.erb'),
    require => Package['rsnapshot'],
  }

  file { '/root/.ssh/rsnapshot_key':
    ensure => present, mode => '0400',
    owner => root, group => root,
    source => 'puppet:///modules/rsnapshot/rsnapshot_key';
  }

  file_line { 'rsnapshot_public_key':
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

