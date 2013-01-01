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
set -ex
PS4=' ${FUNCNAME[0]}: $LINENO: '

: ${VERBOSE:=false}
: ${CONFIG_DIR:=/etc/jenkins}
: ${KEYPAIR_NAME:=jenkins}
: ${PUBKEY_PATH:=$HOME/.ssh/id_rsa.pub}
: ${AVAILABILITY_ZONE:=bm0007}

declare -A PUPPETMASTER
PUPPETMASTER[instance]=puppet
PUPPETMASTER[image]=puppetmaster
PUPPETMASTER[flavor]=e.1-cpu.10GB-disk.512MB-ram

function instance_exists() {
    local instance="$1"

    nova list --name="$instance" | grep "$instance" > /dev/null
}

function instance_delete() {
    local instance="$1"
    
    nova delete "$instance" || return 0
    while nova list --name="$instance" | grep "$instance" > /dev/null ; do sleep 1 ; done
    ssh root@${PUPPETMASTER[instance]} puppetca clean $instance.novalocal || true
}

function instance_run() {
    local instance="$1"
    local image="$2"
    local flavor="$3"

    nova boot \
        --image "$image" \
        --flavor "$flavor" \
        --key_name ${KEYPAIR_NAME} \
        --availability_zone ${AVAILABILITY_ZONE} \
        --poll \
        "$instance"
    while ! nova list --name="$instance" | grep "$instance" ; do sleep 1 ; done
}

function image_exists() {
    local instance="$1"
    local command="glance index name=$instance"

    if ! $command | grep "$instance" > /dev/null ; then
        echo "The command '$command' did not find any image using the ${CONFIG_DIR}/openrc.sh credentials" 
        return 1
    else
        return 0
    fi
}

function key_exists() {
    local name="$1"

    nova keypair-list | grep "$name"
}

function key_add() {
    local name="$1"
    local pubkey="$2"
    local command="nova keypair-add --pub_key \"$pubkey\" \"$name\""

    eval $command

    if ! key_exists "$name" ; then
        echo "The command '$command' was run but 'nova keypair-list' does not show $name"
        return 1
    else
        return 0
    fi
}

function key_exists_or_add() {
    local name="$1"
    local pubkey="$2"

    key_exists "$name" || key_add "$name" "$pubkey"
}

function create_puppetmaster() {
    instance_run puppetmaster puppet e.1-cpu.10GB-disk.512MB-ram || return 1

    while ! nmap puppetmaster -PN -p ssh | grep open ; do sleep 1 ; done
    while ! ssh -o 'StrictHostKeyChecking=false' root@puppetmaster apt-get update -o Acquire::Pdiffs=false ; do sleep 1 ; done
    ssh root@puppetmaster apt-get install -qy puppet augeas-tools puppetmaster sqlite3 libsqlite3-ruby libactiverecord-ruby git
    ssh root@puppetmaster apt-get remove -y ruby1.9.1
    nova image-create --poll puppetmaster puppetmaster 
    nova delete puppetmaster
}

function install_cloud_clients() {
    DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::Pdiffs=false
    DEBIAN_FRONTEND=noninteractive apt-get install -qy python-novaclient euca2ools glance-common nmap
}

function credentials() {
    set +x
    source ${CONFIG_DIR}/openrc.sh
    source ${CONFIG_DIR}/ec2rc.sh
    set -x
}

function run() {
    local git="$1"
    local directory="$2"

    credentials || return 1

    install_cloud_clients || return 2

    cleanup

    key_exists_or_add "${KEYPAIR_NAME}" "${PUBKEY_PATH}" || return 3

    image_exists puppet || return 4

    if ! instance_exists ${PUPPETMASTER[instance]} ; then
        if ! image_exists  ${PUPPETMASTER[image]} ; then
	    create_puppetmaster
	fi
        instance_run ${PUPPETMASTER[instance]} ${PUPPETMASTER[image]} ${PUPPETMASTER[flavor]} || return 5
	while ! nmap ${PUPPETMASTER[instance]} -PN -p ssh | grep open ; do sleep 1 ; done
	while ! ssh -o 'StrictHostKeyChecking=false' root@${PUPPETMASTER[instance]} /etc/init.d/puppetmaster status ; do sleep 1 ; done
	ssh root@${PUPPETMASTER[instance]} apt-get update -o Acquire::Pdiffs=false
	ssh root@${PUPPETMASTER[instance]} rm -fr /etc/puppet/modules/"$directory" 
	ssh root@${PUPPETMASTER[instance]} git clone "$git" /etc/puppet/modules/"$directory"
	ssh root@${PUPPETMASTER[instance]} echo "'DAEMON_OPTS=\"--autosign true\"'" \>\> /etc/default/puppetmaster
        ssh root@${PUPPETMASTER[instance]} puppet module install --version=2.6.0 puppetlabs-stdlib
        ssh root@${PUPPETMASTER[instance]} <<'EOF'
cat > /etc/puppet/puppet.conf <<'INNER_EOF'
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=$vardir/lib/facter
templatedir=$confdir/templates
prerun_command=/etc/puppet/etckeeper-commit-pre
postrun_command=/etc/puppet/etckeeper-commit-post

[master]
# These are needed when the puppetmaster is run by passenger                                               
# and can safely be removed if webrick is used.                                                            
ssl_client_header = SSL_CLIENT_S_DN
ssl_client_verify_header = SSL_CLIENT_VERIFY

storeconfigs=true
dbadapter=sqlite3
dblocation=/var/lib/puppet/server_data/storeconfigs.sqlite
[agent]                                                                                                    
pluginsync=true
INNER_EOF
EOF

        ssh root@${PUPPETMASTER[instance]} <<'EOF'
cat > /etc/puppet/fileserver.conf <<'INNER_EOF'
[files]
  path /etc/puppet/files
  allow *
[modules]
  allow *
[plugins]
  allow *
INNER_EOF
EOF

	ssh root@${PUPPETMASTER[instance]} /etc/init.d/puppetmaster restart
	while ! ssh root@${PUPPETMASTER[instance]} /etc/init.d/puppetmaster status ; do sleep 1 ; done
	ssh root@${PUPPETMASTER[instance]} apt-get install -y rubygems
        ssh root@${PUPPETMASTER[instance]} <<'EOF'
    set -x
    GEM_HOME=$HOME/.gem-installed gem install --ignore-dependencies --no-rdoc --no-ri --version 1.1.3 diff-lcs
    GEM_HOME=$HOME/.gem-installed gem install --ignore-dependencies --no-rdoc --no-ri --version 1.6.14 facter
    GEM_HOME=$HOME/.gem-installed gem install --ignore-dependencies --no-rdoc --no-ri --version 0.0.1 metaclass
    GEM_HOME=$HOME/.gem-installed gem install --ignore-dependencies --no-rdoc --no-ri --version 0.13.0 mocha
    GEM_HOME=$HOME/.gem-installed gem install --ignore-dependencies --no-rdoc --no-ri --version 2.7.18 puppet
    GEM_HOME=$HOME/.gem-installed gem install --ignore-dependencies --no-rdoc --no-ri --version 0.1.13 puppet-lint
    GEM_HOME=$HOME/.gem-installed gem install --ignore-dependencies --no-rdoc --no-ri --version 0.2.0 puppetlabs_spec_helper
    GEM_HOME=$HOME/.gem-installed gem install --ignore-dependencies --no-rdoc --no-ri --version 10.0.2 rake
    GEM_HOME=$HOME/.gem-installed gem install --ignore-dependencies --no-rdoc --no-ri --version 2.12.0 rspec
    GEM_HOME=$HOME/.gem-installed gem install --ignore-dependencies --no-rdoc --no-ri --version 2.12.0 rspec-core
    GEM_HOME=$HOME/.gem-installed gem install --ignore-dependencies --no-rdoc --no-ri --version 2.12.0 rspec-expectations
    GEM_HOME=$HOME/.gem-installed gem install --ignore-dependencies --no-rdoc --no-ri --version 2.12.0 rspec-mocks
    GEM_HOME=$HOME/.gem-installed gem install --ignore-dependencies --no-rdoc --no-ri --version 0.1.4 rspec-puppet
EOF
    else
	ssh  -o 'StrictHostKeyChecking=false' root@${PUPPETMASTER[instance]} <<EOF
set -xe
cd /etc/puppet/modules/"$directory"
git pull
EOF
    fi
    ssh root@${PUPPETMASTER[instance]} rm -f /var/lib/puppet/server_data/storeconfigs.sqlite    
    ssh root@${PUPPETMASTER[instance]} /etc/init.d/puppetmaster restart
    sleep 5 # give the puppet master time to restart. should wait in a more predicatable way.
    ssh root@${PUPPETMASTER[instance]} puppet agent -vt | sed --unbuffered -e 's/^/puppetmaster: /' -e '/Finished catalog run/q'

    # cleanup

    # setup || return 9

    run_tests "$directory" || return 10

    # cleanup
}

function setup() {
    ssh root@${PUPPETMASTER[instance]} export PATH=/root/.gem-installed/bin:\$PATH \; cd /etc/puppet/modules/april_nagios \; GEM_HOME=/root/.gem-installed rake --trace spec || return 7
    instance_run nagios puppet e.1-cpu.10GB-disk.512MB-ram || return 6
    while ! nmap nagios -PN -p ssh | grep open ; do sleep 1 ; done
    ssh -o 'StrictHostKeyChecking=false' root@nagios tail -f /var/log/daemon.log | sed --unbuffered -e 's/^/nagios:pass1: /' -e '/Finished catalog run/q'
    ssh root@nagios /etc/init.d/nagios3 status || return 7
    ssh root@nagios htpasswd -c -b /etc/nagios3/htpasswd.users nagiosadmin admin
    ssh root@nagios puppet agent -vt | sed --unbuffered -e 's/^/nagios:pass2: /' -e '/Finished catalog run/q'

    while ! echo -e "GET hosts\nFilter: name = nagios.novalocal" | \
        ssh root@nagios unixcat /var/lib/nagios3/rw/live | \
        grep "PING OK" ; do 
        sleep 1
    done
}

function cleanup() {
    instance_delete nagios
}

function run_tests() {
    local directory="$1"
    
    for path in $(find * -name test-in-openstack.sh) ; do
        source "$path" || return 1
    done
}

case "$1" in
    TEST)
        # The tests start here
        set -x
        set -o functrace
        PS4=' ${FUNCNAME[0]}: $LINENO: '
        export CONFIG_DIR=tmp
        mkdir ${CONFIG_DIR}
        touch ${CONFIG_DIR}/openrc.sh ${CONFIG_DIR}/ec2rc.sh
        chmod +x ${CONFIG_DIR}/openrc.sh ${CONFIG_DIR}/ec2rc.sh
        ;;

    *)
        CONFIG_DIR="$1"
	AVAILABILITY_ZONE="$2"
	run "$3" "$4"
        ;;
esac

# Interpreted by emacs
# Local Variables:
# compile-command: "bash run-test-in-openstack.sh ???"
# End:
