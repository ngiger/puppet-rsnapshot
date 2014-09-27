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
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'
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

    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(/ionice -c3/) }
    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(/\n15 \*\/4  \* \* \*/) }
    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(/\n30 23  \* \* 1/) }
    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(/\n45 23  1 \* \* /) }
    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(
         /15 \*\/4  \* \* \*  root ionice -c3 \/usr\/bin\/rsnapshot -c \/etc\/rsnapshot.etc.conf hourly\s+>> \/var\/log\/rsnapshot\/etc.hourly.log\n/) }
    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(
         /15 23  \* \* \*  root ionice -c3 \/usr\/bin\/rsnapshot -c \/etc\/rsnapshot.etc.conf daily\s+>> \/var\/log\/rsnapshot\/etc.daily.log\n/) }
    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(
         /30 23  \* \* 1  root ionice -c3 \/usr\/bin\/rsnapshot -c \/etc\/rsnapshot.etc.conf weekly\s+>> \/var\/log\/rsnapshot\/etc.weekly.log\n/) }
    it { should contain_file('/etc/cron.d/rsnapshot_etc').with_content(
         /45 23  1 \* \*  root ionice -c3 \/usr\/bin\/rsnapshot -c \/etc\/rsnapshot.etc.conf monthly\s+>> \/var\/log\/rsnapshot\/etc.monthly.log\n/) }
  end
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
    it { should contain_package('rsync').with_ensure(/present|installed/) }
    it { should contain_package('rsnapshot').with_ensure(/present|installed/) }

    it { should contain_file('/etc/rsnapshot.demo.conf').with_content(/\nsnapshot_root\t\/var\/cache\/backup\n/) }
    it { should contain_file('/etc/rsnapshot.demo.conf').with_content(/\nexclude\t\/var/) }
    it { should contain_file('/etc/rsnapshot.demo.conf').with_content(/\nexclude\t\/etc\/.git\/\n/) }
    it { should contain_file('/etc/rsnapshot.demo.conf').with_content(/\nbackup\t\/etc\t\.\n/) }
    it { should contain_file('/etc/rsnapshot.demo.conf').with_content(/\nbackup\t\/special\t\.\n/) }

    it { should contain_file('/etc/cron.d/rsnapshot_demo').without_content(/ionice/) }
    it { should contain_file('/etc/cron.d/rsnapshot_demo').without_content(/hourly/) }
    it { should contain_file('/etc/cron.d/rsnapshot_demo').without_content(/daily/) }
    it { should contain_file('/etc/cron.d/rsnapshot_demo').without_content(/weekly/) }
    it { should contain_file('/etc/cron.d/rsnapshot_demo').without_content(/monthly/) }
  end
end
