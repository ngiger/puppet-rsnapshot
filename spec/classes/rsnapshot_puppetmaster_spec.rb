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

describe 'rsnapshot::puppetmaster' do

  context 'when running on Debian GNU/Linux' do

    it {
      should contain_file('/etc/puppet/modules/rsnapshot/files').with_ensure('directory')
      should contain_exec('create_key').with_creates('/etc/puppet/modules/rsnapshot/files/rsnapshot_key')
    }
      
  end

end
