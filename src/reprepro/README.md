# Reprepro Docker Container

This container is a fully working installation of reprepro (and accessory packages) that allows you to create a repository for your debian packages in 5 minutes with a minimal configuration.
It is completely customizable and allows you to use as many repositories as you want within the same container with the appropriate configuration.

It also allows you to add a website made up of html pages, css styles and javascript scripts without the least effort, showing the content you prefer related to the hosted repositories.

It also offers handy scripts to automate the deployment and update of mirrored packages, useful for both the manual launch of the same and for integration with various CI/CD tools. Of course, these too are fully customizable and extendable to your liking.

Each folder contains within it a README.txt file that explains the contents and the purpose of the same to always have at hand the key information related to the installation even in the shell environment.

## Quick setup
- First step, you need to generate an SSH key.
	If you already have a key to use you can jump to next step

		ssh-keygen -t rsa

- Second step, you need a full GPG database containing a public and a private key for package and repository signing.
	If you already have one you can jump to next step

	**WARNING:** You **MUST** create your keypair with GPG version 1. If you are not careful with this problem, your repository will not be able to sign the files and therefore the deployment of the packages will fail.

	Generate a GPG key pair. Your key must use RSA and must be at least 4096 bits without password.

		gpg1 --homedir /tmp/repo-keys --gen-key

	Use this command to list previously created GPG keys. Your key id is like this *3AA5C34371567BD2*

		gpg1 --homedir /tmp/repo-keys --list-secret-keys --keyid-format LONG

	Export your public key for later use (replace example ID with your real ID)

		gpg1 --homedir /tmp/repo-keys --armor --output my-repo.pubkey.gpg --export 3AA5C34371567BD2

- After you have done this first 2 steps, you are ready to initialize repository.
	Start the container:

		docker run -d -p 2022:22 -p 8080:80 -v reprepro_data:/repo wolfetti/reprepro

	Install (as root user) your SSH public key.

	**WARNING:** This may depend on your volume creation and your SSH key type.

		sudo cat /home/your_user/.ssh/id_rsa.pub > /var/lib/docker/volumes/reprepro_data/_data/ssh/authorized_keys

	Set some variables for easy copy/paste of the last commands, like this example

		REPO_NAME="my-repo"
		GPG_KEY_ID="3AA5C34371567BD2"
		SSH_PORT=2022
		SSH_HOST="localhost"

	Let's make sure that the GPG signature database folder has the right permissions:

		ssh root@$SSH_HOST -p $SSH_PORT "chmod 700 /repo/gnupg /root/.gnupg && chown -R root:root /root/.gnupg /repo/gnupg"

	Update reprepro configuration files with your repository data

		ssh root@$SSH_HOST -p $SSH_PORT "sed -i \"s/YOUR_GPG_KEY_ID/$GPG_KEY_ID/g\" /repo/conf/distributions"
		ssh root@$SSH_HOST -p $SSH_PORT "sed -i \"s/YOUR_GPG_KEY_ID/$GPG_KEY_ID/g\" /repo/gnupg/gpg_sign_key_id"
		ssh root@$SSH_HOST -p $SSH_PORT "sed -i \"s/YOUR_REPO_NAME/$REPO_NAME/g\" /repo/conf/distributions"
		ssh root@$SSH_HOST -p $SSH_PORT "sed -i \"s/YOUR_REPO_NAME/$REPO_NAME/g\" /repo/conf/incoming"

	Copy your gpg database

		scp -P $SSH_PORT /tmp/repo-keys/* root@$SSH_HOST:/repo/gnupg

	(OPTIONAL) Copy your public key to */repo/public* to allow clients to install the key directly from the repository website

		scp -P $SSH_PORT my-repo.pubkey.gpg root@$SSH_HOST:/repo/public/$REPO_NAME.pubkey.gpg

	**DONE!** You are ready to use your fresh debian repository ;)

## Provided scripts
This image contains 2 scripts ready for usage with quick setup installation. They must be invoked as root user with SSH (install SSH keys first for user authorization)

- The first script is a simple mirror update tool.

		ssh root@$SSH_HOST -p $SSH_PORT repo-update-mirrors

	If you want to enable automatic update you can run this script in cron, for example:
	
		ssh root@$SSH_HOST -p $SSH_PORT "ln -s /repo/bin/repo-update-mirrors /repo/cron/cron.daily/"

- The second script must be invoked manually (or by a shell script in your favorite CI/CD tool) and must be invoked like this example

	First step, you have to upload your *.changes* and *.deb* files to */repo/incoming* folder

		DIR="/your/artifact/folder"
		scp -P $SSH_PORT $DIR/*.deb $DIR/*.changes root@$SSH_HOST:/repo/incoming

	Finally you can invoke the script for package deploy

		ssh root@$SSH_HOST -p $SSH_PORT "repo-process-incoming $REPO_NAME"

## That's all!
For customized configuration, please refer to official [reprepro](https://manpages.debian.org/buster/reprepro/reprepro.1.en.html) man page
