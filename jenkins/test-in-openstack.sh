#!/bin/bash
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
function run_test() {
    local module=rsnapshot
    ssh root@puppet cd /etc/puppet/modules/$module \; 'GEM_HOME=$HOME/.gem-installed' 'PATH=$HOME/.gem-installed/bin:$PATH' rake spec || return 1

    local instance=rsnapshot
    #
    # setup
    #
    ssh root@puppet <<EOF
set -x

cat > /etc/puppet/manifests/site.pp <<'INNER_EOF'
node '$instance.novalocal' {
  class { 'rsnapshot::server': }
  class { 'rsnapshot::client': 
     excludes => [ '/etc/passwd', '/etc/group' ],
  }
  class { 'rsnapshot::nagios': }
}

node 'puppet.novalocal' {
  class { 'rsnapshot::puppetmaster': }
}
INNER_EOF

EOF
    ssh root@puppet rm -f '/etc/puppet/modules/rsnapshot/files/rsnapshot_key*'
    ssh root@puppet puppet agent -vt | sed --unbuffered -e 's/^/puppetmaster: /' -e '/Finished catalog run/q'
    instance_delete $instance
    instance_run $instance puppet e.1-cpu.10GB-disk.512MB-ram || return 1
    while ! nmap $instance -PN -p ssh | grep open ; do sleep 1 ; done
    ssh -o 'StrictHostKeyChecking=false' root@$instance tail -f /var/log/daemon.log | sed --unbuffered -e "s/^/$instance: /" -e '/Finished catalog run/q' 

    ssh root@$instance test -f /etc/rsnapshot.conf || return 2
    ssh root@$instance for i in /var/cache/rsnapshot/*.conf \; do /usr/bin/rsnapshot -c \$i daily \; done || return 3
    ssh root@$instance /usr/lib/nagios/plugins/check_rsnapshot TEST || return 4
    ssh root@$instance /usr/lib/nagios/plugins/check_rsnapshot || return 5
    #
    # teardown
    #
    instance_delete $instance
}

run_test
