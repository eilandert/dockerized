
Aptly is a swiss army knife for Debian repository management: it allows you to mirror remote repositories, manage local package repositories, take snapshots, pull new versions of packages along with dependencies, publish as Debian repository.

Quick start: (without snapshots)

1) pull the docker
2) bind a local dir to /aptly
3) start docker
4) put your gpg keys in /aptly/gnupg
5) put your public sshkey in /aptly/ssh
6) gpg --output /aptly/repo/public/key.pub --armor --export <YOUR GPG ID HERE>
7) ssh to the docker as aptly, like aptly@localhost
8) create a repo, cmd: ssh aptly@localhost "aptly repo create -distribution=focal -component=main focal"
9) publish the repo, cmd: ssh aptly@localhost "aptly publish update focal" 
10) upload your debs and .changes files with scp (or rsync), cmd: scp *deb *changes aptly@localhost:incoming
11) process the debs, cmd: ssh aptly@localhost "aptly repo include ~/incoming" 
12) publish the repo, cmd: ssh aptly@localhost "aptly publish update focal" 

You should automate steps 10-12 in your buildscripts

Environment:
  - TZ=Europe/Amsterdam
  - SYSLOG_HOST=10.0.0.1
  - CLEANDBONSTART=YES
  - NGINX=YES
