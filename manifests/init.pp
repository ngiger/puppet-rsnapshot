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

class rsnapshot::puppetmaster {
  file {
    "/etc/puppet/modules/rsnapshot/files":
      ensure => directory, mode => 0700,
      owner => puppet, group => nogroup,
  }

  exec { 'create_key':
    command => '/usr/bin/ssh-keygen -N "" -f /etc/puppet/modules/rsnapshot/files/rsnapshot_key ; chown puppet /etc/puppet/modules/rsnapshot/files/rsnapshot_key*',
    creates => '/etc/puppet/modules/rsnapshot/files/rsnapshot_key',
    require => File['/etc/puppet/modules/rsnapshot/files'],
  }
}

class rsnapshot::nagios {
  file {
    "/usr/lib/nagios":
      ensure => directory, mode => 0755,
      owner => root, group => root;
    "/usr/lib/nagios/plugins":
      ensure => directory, mode => 0755,
      owner => root, group => root;
    "/usr/lib/nagios/plugins/check_rsnapshot":
      ensure => present, mode => 0555,
      owner => root, group => root,
      source => 'puppet:///rsnapshot/check_rsnapshot';
  }
}

class rsnapshot::server (
  $ip = $::ipaddress,
  ) {
  package { 'rsnapshot':
    ensure => installed
  }

  file { "/etc/logrotate.d/rsnapshot":
    ensure => present, mode => 0444,
    owner => root, group => root,
    source => 'puppet:///rsnapshot/logrotate.d/rsnapshot',
    require => Package['rsnapshot'],
  }

  file { "/etc/cron.d/rsnapshot":
    ensure => present, mode => 0444,
    owner => root, group => root,
    source => 'puppet:///rsnapshot/cron.d/rsnapshot',
    require => Package['rsnapshot'],
  }

  file { "/root/.ssh/rsnapshot_key":
    ensure => present, mode => 0400,
    owner => root, group => root,
    source => 'puppet:///rsnapshot/rsnapshot_key';
  }

  $public_key = file('/etc/puppet/modules/rsnapshot/files/rsnapshot_key.pub')
  
  @@file_line { 'rsnapshot_public_key':
    ensure => present,
    path => '/root/.ssh/authorized_keys',
    line => "from=\"127.0.0.1,$ip\",command=\"echo \\\"\$SSH_ORIGINAL_COMMAND\\\" | grep --quiet '^rsync --server --sender' && ionice -c3 \$SSH_ORIGINAL_COMMAND\" $public_key",
    tag => 'rsnapshot',
  }

  File <<| tag == 'rsnapshot' |>>

  file {
    "/var/run/rsnapshot/":
      ensure => directory,
      mode => '0755', owner => root, group => root;
    "/var/log/rsnapshot/":
      ensure => directory,
      mode => '0755', owner => root, group => root;
  }
}

class rsnapshot::client (
  $excludes = [],
  ) {
  
  File_line <<| tag == 'rsnapshot' |>>

  @@file { "/var/cache/rsnapshot/${::fqdn}.conf":
    ensure => present,
    mode => '0444', owner => root, group => root,
    content => template('rsnapshot/rsnapshot.conf.erb'),
    require => Package['rsnapshot'],
    tag => 'rsnapshot',
  }
}
