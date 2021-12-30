
Aptly is a swiss army knife for Debian repository management: it allows you to mirror remote repositories, manage local package repositories, take snapshots, pull new versions of packages along with dependencies, publish as Debian repository.

Quick start: (without snapshots)

1) pull the docker
2) bind a local dir to /aptly  (and a dir to /etc/ssh or your serverkey will change on each pull)
3) start docker
4) put your public sshkey in /aptly/.ssh
5) put your gpg keys in /aptly/.gnupg
6) create a public key, cmd: ssh aptly@localhost "gpg --output /aptly/repo/public/key.pub --armor --export <YOUR GPG ID HERE>"
-
7) upload your debs and .changes files with scp (or rsync), process the debs and publish the snapshot or repo

You should automate step 7 in your buildscripts. See the scripts in examples for more automation

Environment:
  - TZ=Europe/Amsterdam
  - SYSLOG_HOST=10.0.0.1
  - CLEANDBONSTART=YES      # aptly db cleanup
  - STARTNGINX=YES          # start a webserver on port 80
