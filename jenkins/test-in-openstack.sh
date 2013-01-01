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
    local instance=rsnapshot
    #
    # setup
    #
    ssh root@puppet <<EOF
set -x

cat > /etc/puppet/manifests/site.pp <<'INNER_EOF'
node '$instance.novalocal' {
  include rsnapshot::server
  include rsnapshot::host
}

node 'puppet.novalocal' {
  include rsnapshot::puppetmaster
}
INNER_EOF

EOF
    instance_delete $instance
    instance_run $instance puppet e.1-cpu.10GB-disk.512MB-ram || return 1
    while ! nmap $instance -PN -p ssh | grep open ; do sleep 1 ; done
    ssh -o 'StrictHostKeyChecking=false' root@$instance tail -f /var/log/daemon.log | sed --unbuffered -e "s/^/$instance: /" -e '/Finished catalog run/q' 

    ssh root@$instance test -f /etc/rsnapshot.conf || return 2

    #
    # teardown
    #
    instance_delete $instance
}

run_test
