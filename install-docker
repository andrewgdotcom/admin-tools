#!/bin/bash

BRANCH=master

SCRIPT_DIR=$(dirname $(readlink -f $0))

if [[ ! -x ${SCRIPT_DIR}/apt-repo ]]; then
    # We are probably inside ansible; let's hope it forwarded our agent!
    if ! grep -q github.com ~/.ssh/known_hosts; then
        cat <<EOF >>~/.ssh/known_hosts
github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
EOF
    fi
    TMPDIR=$(mktemp -d)
    cd $TMPDIR
    git clone -b ${BRANCH} git@github.com:andrewgdotcom/admin-tools
    SCRIPT_DIR=${TMPDIR}/admin-tools
fi

${SCRIPT_DIR}/apt-repo add docker "https://download.docker.com/linux/ubuntu xenial stable" https://download.docker.com/linux/ubuntu/gpg || true
apt-get update
# make sure the installer does not prompt; there's nobody listening
DEBIAN_FRONTEND=noninteractive apt-get -y install docker-ce

if [[ $NO_DOCKER_NETWORKING ]]; then
	echo "Not configuring docker networking"
	exit 0
fi

if unbound-control status | grep -q "is running ..."; then

	echo "Unbound detected"
	echo "Attempting to configure docker to use local DNS resolver"

	if [[ -f /etc/docker/daemon.json ]]; then
		echo "Docker appears to be already configured. Aborting"
	fi
	if [[ -f /etc/unbound/unbound.conf.d/server.conf ]]; then
		echo "Unbound appears to be already configured. Aborting"
	fi

	if [[ $DISABLE_IPTABLES ]] ; then
		cat > /etc/docker/daemon.json <<EOF
{
  "storage-driver": "overlay2",
  "iptables": false,
  "dns": ["172.17.0.1"]
}
EOF
	else
		cat > /etc/docker/daemon.json <<EOF
{
  "storage-driver": "overlay2",
  "dns": ["172.17.0.1"]
}
EOF
	fi

	service docker restart

	cat > /etc/unbound/unbound.conf.d/server.conf <<EOF
# Local server configuration
# Listen on secure interfaces only - this allows us to be used recursively

server:
	interface: 127.0.0.1
	interface: 172.17.0.1  # docker
	access-control: 172.17.0.0/16 allow
	access-control: 127.0.0.0/8 allow
EOF
	service unbound restart

fi

if grep -q '^*nat' /etc/ufw/before.rules; then
  if [[ $DISABLE_IPTABLES ]]; then

	echo "Re-enabling outgoing firewall rules for docker containers"

	TMP=$(mktemp)
	cat >$/etc/ufw/before.rules <<EOF

# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]

# Masquerade outgoing traffic coming from the docker subnet
-A POSTROUTING -o !docker0 -s 172.17.0.0/16 -j MASQUERADE
COMMIT
EOF

	if [[ $(ufw status | head) == "Status: active" ]]; then
		ufw disable; yes | ufw enable
	fi

  fi
fi

[[ $TMPDIR ]] && rm -rf $TMPDIR
