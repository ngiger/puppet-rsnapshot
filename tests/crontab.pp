# The baseline for module testing used by Puppet Labs is that each manifest
# should have a corresponding test manifest that declares that class or defined
# type.
#
# Tests are then run by using puppet apply --noop (to check for compilation errors
# and view a log of events) or by fully applying the test in a virtual environment
# (to compare the resulting system state to the desired state).
#
# Learn more about module testing here: http://docs.puppetlabs.com/guides/tests_smoke.html
#

rsnapshot::crontab{"demo_rsnapshot":
  name     => "etc",
  excludes => ['/etc/.git/'],
  includes => ['/etc'], # Default is ['/'], backup everything
  destination  => "/var/cache/backup",
  ionice       => "ionice -c3",
  time_hourly  => "15 */4", # every four hours 
  time_daily   => "15 23",  # 11 PM 15
  time_weekly  => "30 23",
  time_monthly => "45 23",
                 }