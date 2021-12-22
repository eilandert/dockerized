
Aptly is a swiss army knife for Debian repository management: it allows you to mirror remote repositories, manage local package repositories, take snapshots, pull new versions of packages along with dependencies, publish as Debian repository.

Quick start: (without snapshots)

1) pull the docker
2) bind a local dir to /aptly
3) start docker
4) put your public sshkey in /aptly/ssh
5) put your gpg keys in /aptly/gnupg
6) create a public key, cmd: ssh aptly@localhost "gpg --output /aptly/repo/public/key.pub --armor --export <YOUR GPG ID HERE>"
7) create a repo, cmd: ssh aptly@localhost "aptly repo create -distribution=focal -component=main focal"
-
8) upload your debs and .changes files with scp (or rsync), cmd: scp *deb *changes *buildinfo aptly@localhost:incoming
9) process the debs, cmd: ssh aptly@localhost "aptly repo include /aptly/incoming" 
10) publish the repo, cmd: ssh aptly@localhost "aptly publish repo focal" 

You should automate steps 8-10 in your buildscripts

On docker restart aptly will cleanup the database, the accessrights will be set to user aptly and nginx will start for webaccess.

Environment:
  - TZ=Europe/Amsterdam
  - SYSLOG_HOST=10.0.0.1
  - CLEANDBONSTART=YES
  - NGINX=YES
