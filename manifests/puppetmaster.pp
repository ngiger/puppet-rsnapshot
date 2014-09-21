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
  file { '/etc/puppet/modules/rsnapshot/files':
    ensure => directory,
    mode   => '0700',
    owner  => puppet,
    group  => nogroup,
  }

  exec { 'create_key':
    command => '/usr/bin/ssh-keygen -N "" -f /etc/puppet/modules/rsnapshot/files/rsnapshot_key ; chown puppet /etc/puppet/modules/rsnapshot/files/rsnapshot_key*',
    creates => '/etc/puppet/modules/rsnapshot/files/rsnapshot_key',
    require => File['/etc/puppet/modules/rsnapshot/files'],
  }
}
