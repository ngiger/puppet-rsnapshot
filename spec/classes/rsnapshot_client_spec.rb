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
require 'spec_helper'

describe 'rsnapshot::client' do
  let(:node) { 'testhost.example.com' }

  context 'when running on Debian GNU/Linux' do
    it {
      should contain_package('rsync').with_ensure(/present|installed/)
      should contain_package('rsnapshot').with_ensure(/present|installed/)
      should contain_file('/var/cache/rsnapshot/testhost.example.com.conf').with_content(/\nbackup\troot@testhost.example.com:\/\t./)
    }
  end
end

describe 'rsnapshot::client' do
  let(:node) { 'testhost.example.com' }
  let(:params) { {:excludes => ['/media/debian']} }
  context 'when given excludes it should not backup these directories' do

    it {
      should contain_package('rsnapshot').with_ensure(/present|installed/)
      should contain_file('/var/cache/rsnapshot/testhost.example.com.conf').with_content(/\nbackup\troot@testhost.example.com:\/\t./)
      should contain_file('/var/cache/rsnapshot/testhost.example.com.conf').with_content(/\nexclude\t\/media\/debian/)
    }
      
  end

end
