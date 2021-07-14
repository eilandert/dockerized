In this folder you must insert your GPG stores and keys for package signature.
If you add your SSH key in /repo/ssh/authorized_keys, you can ssh this host
as root user and create your keys, which are automatically added here

WARN: It seems that keys generated with gpg2 (the default on most linux system)
      cause container's GPG to not recognize the key. A workaround to this
      problem is to generate gpg keypairs with gpg1
