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

describe 'rsnapshot::server' do

  context 'when running on Debian GNU/Linux' do

    it {
      should contain_package('rsnapshot').with_ensure('installed')
      should contain_file('/etc/logrotate.d/rsnapshot')
      should contain_file('/root/.ssh/rsnapshot_key')
      # should contain_file('/root/.ssh/authorized_keys')
      should contain_file('/var/log/rsnapshot/').with_ensure('directory')
      should contain_file('/etc/cron.d/rsnapshot') # .with_content(/./)
    }

  end

end

