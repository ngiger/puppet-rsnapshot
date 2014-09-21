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
      source => 'puppet:///modules/rsnapshot/check_rsnapshot';
  }
}

