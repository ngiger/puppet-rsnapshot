#
#    Copyright (C) 2013 Loic Dachary <loic@dachary.org>
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
require 'spec_helper'

describe "split()" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  it "should split 'one;two' on ';' into [ 'one', 'two' ]" do
    scope.function_split(['one;two', ';']).should == [ 'one', 'two' ]
  end
end

describe 'rsnapshot::crontab' do
  let(:node) { 'testhost.example.com' }
  let(:title) { 'etc' }
  let(:params) { {
            :excludes => ['/etc/.git/', '/etc/hosts'],
            :includes => ['/etc', '/special'],
            :destination  => '/var/cache/backup',
            :ionice       => 'ionice -c3',
            :time_hourly  => '15 */4',
            :time_daily   => '15 23',
            :time_weekly  => '30 23',
            :time_monthly => '45 23',
          } }

  context 'when running on Debian GNU/Linux' do
    it { should contain_package('rsync').with_ensure(/present|installed/) }
    it { should contain_package('rsnapshot').with_ensure(/present|installed/) }

    it { should contain_file('/etc/rsnapshot.etc.conf').with_content(/\nsnapshot_root\t\/var\/cache\/backup\n/) }
    it { should contain_file('/etc/rsnapshot.etc.conf').with_content(/\nexclude\t\/var/) }
    it { should contain_file('/etc/rsnapshot.etc.conf').with_content(/\nexclude\t\/etc\/.git\/\n/) }
    it { should contain_file('/etc/rsnapshot.etc.conf').with_content(/\nbackup\t\/etc\t\.\n/) }
    it { should contain_file('/etc/rsnapshot.etc.conf').with_content(/\nbackup\t\/special\t\.\n/) }
    it { should contain_file('/etc/rsnapshot.etc.conf').without_content(/\/var\/log\/rsnapshot/) }

    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(/ionice -c3/) }
    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(/\n15 \*\/4  \* \* \*/) }
    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(/\n30 23  \* \* 1/) }
    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(/\n45 23  1 \* \* /) }
    it { should contain_file('/etc/cron.d/rsnapshot_etc').without_content(/\s+>>\s+\/var\/log\/rsnapshot/) }
    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(
         /15 \*\/4  \* \* \*  root ionice -c3 \/usr\/bin\/rsnapshot -q -c \/etc\/rsnapshot.etc.conf hourly/) }
    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(
         /15 23  \* \* \*  root ionice -c3 \/usr\/bin\/rsnapshot -q -c \/etc\/rsnapshot.etc.conf daily/) }
    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(
         /30 23  \* \* 1  root ionice -c3 \/usr\/bin\/rsnapshot -q -c \/etc\/rsnapshot.etc.conf weekly/) }
    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(
         /45 23  1 \* \*  root ionice -c3 \/usr\/bin\/rsnapshot -q -c \/etc\/rsnapshot.etc.conf monthly/) }
    it { should contain_file('/var/log/rsnapshot/').with_ensure('directory') }
  end
#        +45 23  1 * *  root ionice -c3 /usr/bin/rsnapshot -q -c/etc/rsnapshot.etc.conf monthly  >> /var/log/rsnapshot/etc.monthly.log

end

describe 'rsnapshot::crontab' do
  let(:node) { 'testhost.example.com' }
  let(:title) { 'demo' }
  let(:params) { {
            :excludes => ['/etc/.git/', '/etc/hosts'],
            :includes => ['/etc', '/special'],
            :destination  => '/var/cache/backup',
            :ionice       => nil,
            :time_hourly  => nil,
            :time_daily   => nil,
            :time_weekly  => nil,
            :time_monthly => nil,
          } }

  context 'when running on Debian GNU/Linux' do
    it {
      should contain_package('rsync').with_ensure(/present|installed/)
      should contain_package('rsnapshot').with_ensure(/present|installed/)

      should contain_file('/etc/rsnapshot.demo.conf').with_content(/\nsnapshot_root\t\/var\/cache\/backup\n/)
      should contain_file('/etc/rsnapshot.demo.conf').with_content(/\nexclude\t\/var/)
      should contain_file('/etc/rsnapshot.demo.conf').with_content(/\nexclude\t\/etc\/.git\/\n/)
      should contain_file('/etc/rsnapshot.demo.conf').with_content(/\nbackup\t\/etc\t\.\n/)
      should contain_file('/etc/rsnapshot.demo.conf').with_content(/\nbackup\t\/special\t\.\n/)

      should contain_file('/etc/cron.d/rsnapshot_demo').without_content(/ionice/)
      should contain_file('/etc/cron.d/rsnapshot_demo').without_content(/hourly/)
      should contain_file('/etc/cron.d/rsnapshot_demo').without_content(/daily/)
      should contain_file('/etc/cron.d/rsnapshot_demo').without_content(/weekly/)
      should contain_file('/etc/cron.d/rsnapshot_demo').without_content(/monthly/)
      should contain_file('/var/log/rsnapshot/').with_ensure('directory')
  }
  end
end

describe 'rsnapshot::crontab' do
  let(:node) { 'testhost.example.com' }
  let(:title) { 'cust_cfg' }
  let(:params) { {
            :excludes => ['/etc/.git/', '/etc/hosts'],
            :includes => ['/etc', '/special'],
            :destination  => '/var/cache/backup',
            :custom_config => '/etc/rsnapshot.custom.conf',
            :ionice       => " -3",
            :time_hourly  => 5,
            :time_daily   => 4,
            :time_weekly  => 3,
            :time_monthly => 2,
          } }

  context 'when running on Debian GNU/Linux' do
    it {
      should contain_package('rsync').with_ensure(/present|installed/)
      should contain_package('rsnapshot').with_ensure(/present|installed/)

      should_not contain_file(@custom_config)

      common = '\s+[1\*]\s+\*\s+[1\*]\s+root\s+-3\s+.usr.bin.rsnapshot -q -c .etc.rsnapshot.custom.conf'
      should_not contain_file('/etc/rsnapshot.custom.conf') # or clients of our module cannot define it as they want

      should contain_file('/etc/cron.d/rsnapshot_cust_cfg').with_content(/5#{common} hourly/)
      should contain_file('/etc/cron.d/rsnapshot_cust_cfg').with_content(/4#{common} daily/)
      should contain_file('/etc/cron.d/rsnapshot_cust_cfg').with_content(/3#{common} weekly/)
      should contain_file('/etc/cron.d/rsnapshot_cust_cfg').with_content(/2#{common} monthly/)
      should contain_file('/etc/cron.d/rsnapshot_cust_cfg').without_content(/\s+>>\s+\/var\/log\/rsnapshot/)
      should contain_file('/var/log/rsnapshot/').with_ensure('directory')
  }
  end
end
