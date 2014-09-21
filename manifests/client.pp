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
    ensure  => present,
    mode    => '0444',
    owner   => root,
    group   => root,
    content => template('rsnapshot/rsnapshot.conf.erb'),
    require => Package['rsnapshot'],
    tag     => 'rsnapshot',
  }
}
