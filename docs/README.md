admin-tools
===========

An eclectic selection of system administration tools.

General system administration
-----------------------------

- apt-repo
    Add an APT repository line with PGP signature by specifying the repository
    definition as the first argument and the URL to the PGP signing key in
    the second.

- borgsetup
	Install and configure borg, borgmatic with a sensible set of defaults

- borg-silencer.pl
    A wrapper script that prevents borg from throwing annoying compatibility
    warnings, but lets other errors through. Very useful for cron jobs.

- borgmatic-build-excludes
    Canonicalise the excludes list in a borgmatic config using `readlink -f`

- install-docker
    DO NOT USE

- install-java8
    Configure an APT repository for webupd8team and install oracle java8

- multigit
    Perform the same operation on all git repos under PWD.

- certinfo
    Print a summary of a PEM or JKS keystore in JSON format.

Quick fixer scripts for badly configured systems
------------------------------------------------

- systemd-fixer
    Canonicalise the soft-link structure under /etc/systemd/system

- supervisor-to-systemd
    Convert supervisor-driven services to systemd

- certbot-fixer
    Drag crufty letsencrypt setups up to certbot 0.20 standard

Zerotier handy tools
--------------------

- ztenable
    Enable zerotier join requests via the zerotier API, using the same config
    file as ztsetup.

- ztsetup
	Install and configure zerotier with a prepopulated list of networks

- ztlockdown
	Configure ufw to enforce ssh access only over zerotier

User-authentication tools
------------------------

- monkeyproof
	Install and configure monkeysphere, libpam-ssh-agent-auth for pubkey-only auth

- make-pubkey-users
	Bulk create users pubkey-auth only and optionally prepopulate authorized_keys

- convert-pubkey-users
	Bulk convert existing users to use pubkey-auth only

- install-pam-ldap
    Install and configure libpam-ldap

- dropbear-monkeysphere
    A tool to configure dropbear+monkeysphere to allow remote ssh connections
    during boot. Useful for unlocking crypted volumes at boot time, remotely.

Script tools
------------

- parse-opt.sh
    A tool to help other scripts parse getopt-style command line arguments.
