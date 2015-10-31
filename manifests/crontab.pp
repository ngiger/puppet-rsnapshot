#
#    Copyright (C) 2014 Niklaus Giger <niklaus.giger@member.fsf.org>
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
# == Class: rsnapshot::crontab
#
# Create a rsnapshot configuration file which is run via crontab
#
# === Parameters
#
# The title will be use as name for the given configutation. The following files will be created
#      /etc/rsnapshot/${title}.conf
#      /etc/cron.d/rsnapshot_<title>
#
# [*excludes*]
#   An array of strings used to compose the *--exclude* arguments of
#   the rsync command. (defaults to []).
#
# [*includes*]
#   An array of directory names to backup. Defaults to ['/'] to backup everything.
#
# [*destination*]
#   destination of the backup. May be a host reachable via rsync or
#   or a NFS mounted
#
# [*ionice*]
#   Preceed the rsnapshot command with ionice to minimize impact
#   defaults to "ionice -c3". 3 == idle
#
# [*$custom_config*]
#   Use the given rsnapshot_config file.
#   defaults to false
#
# [*time_hourly*]
#   crontab time when hourly backups should be started
#   defaults to "". not run
#
# [*time_daily*]
#   crontab time when daily backups should be started
#   defaults to "30 3" (3:30AM)
#
# [*time_weekly*]
#   crontab time when weekly backups should be started
#   defaults to "0  3" (0:30AM)
#
# [*time_monthly*]
#   crontab time when monthly backups should be started
#   defaults to "30 2" (2:30AM)
#
# === Variables
#
# [*$::fqdn*]
#   Is used as a name for the configuration file and within the
#   configuration file itself to create unique files.
#
# === Example
#
#  rsnapshot::crontab{"demo":
#    excludes     => ['/etc/.git/'],
#    includes     => ['/etc'],
#    destination  => "/var/cache/backup",
#    ionice       => "ionice -c3",
#    time_hourly  => "15 */4", # every four hours
#    time_daily   => "15 23",  # 11 PM 15
#    time_weekly  => "30 23",
#    time_monthly => "45 23",
#   }
#

define rsnapshot::crontab (
  $excludes = [],
  $includes = [], # Default is ['/'], backup everything
  $destination  = '',
  $ionice       = 'ionice -c3',
  $custom_config= false,
  $time_hourly  = nil,
  $time_daily   = '30 3',
  $time_weekly  = '0  3',
  $time_monthly = '30 2',
  ) {
  ensure_packages(['rsync', 'rsnapshot'], {ensure => present})

  if ($custom_config) {
    $config_file = $custom_config
    $log_file_base = "/var/log/rsnapshot/${title}"
  } else {
    $config_file =  "/etc/rsnapshot.${title}.conf"
    $log_file_base = "/var/log/rsnapshot/${title}"
    file { $config_file:
      ensure  => present,
      mode    => '0444',
      owner   => root,
      group   => root,
      content => template('rsnapshot/rsnapshot.conf.erb'),
      require => Package['rsnapshot'],
      tag     => 'rsnapshot',
    }
  }

  file { "/etc/cron.d/rsnapshot_${title}":
    ensure  => present,
    mode    => '0444',
    owner   => root,
    group   => root,
    content => template('rsnapshot/cron.d/rsnapshot_crontab.erb'),
    require => Package['rsnapshot'],
  }
  ensure_resource('file', ['/var/run/rsnapshot/',  '/var/log/rsnapshot/'], {ensure => directory,  mode => '0755', owner => root, group => root} )
}

