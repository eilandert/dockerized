Latest OpenSSH, installed from https://deb.paranoid.nl , meant to be a jumphost.

Daily rebuilds

Bind /etc/ssh, /home, /etc/passwd, /etc/shadow, /etc/groups to your local dir

If sshd_config is not found, bootstrap wil create /etc/ssh and create new server keys.

If no serverkeys are found, new ones will be generated.

Login: root/toor  (please change password or better: make a new account and disable root login in sshd_config)

Environment variable(s):

      - TZ=Europe/Amsterdam
      - SYSLOG_HOST=10.0.0.118
