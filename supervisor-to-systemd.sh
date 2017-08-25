#!/bin/bash

# QAD script to migrate supervisor configurations to systemd

for superconf in /etc/supervisor/conf.d/*.conf; do
	program=$(perl -ne 'print if s/^\[program:(.*)\]$/$1/' $superconf )
	user=$(perl -ne 'print if s/^user=(.*)$/$1/' $superconf )
	directory=$(perl -ne 'print if s/^directory=(.*)$/$1/' $superconf )
	command=$(perl -ne 'print if s/^command=(.*)$/$1/' $superconf )
	
	if [[ ! $program || ! $user || ! $directory || ! $command ]]; then
		echo "Could not parse config file $superconf"
		exit 1
	fi
	
	if grep -q ^environment= $superconf; then
		perl -ne 's/(^environment=)(.*)$/ $2/ && { $flag=1 }; s/^\s+// || { $flag=0 }; if($flag && /./) {print}' $superconf >$(dirname $directory)/${program}.environment
	fi
	
	cat <<EOF >/etc/systemd/system/multi-user.target.wants/${program}.service
[Unit]
Description=${program}
After=network.target auditd.service

[Service]
WorkingDirectory=${directory}
EnvironmentFile=-$(dirname $directory)/${program}.environment
ExecStart=${command}
KillMode=process
Restart=on-failure
RestartPreventExitStatus=255
Type=simple
User=${user}

[Install]
WantedBy=multi-user.target
Alias=${program}.service
EOF

done

systemctl daemon-reload

