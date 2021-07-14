#!/bin/bash
SRC="./test/pkg"
SSH_PORT=34022
SSH_KEY="$(pwd)/test/ssh/test_id_rsa"
GPG_KEY_ID="510F32A46BC88322"
REPO_NAME="wolfetti-docker-reprepro-dev-repo"

# Copy test key and setup test repository
scp -i $SSH_KEY -P $SSH_PORT test/gnupg/* root@localhost:/repo/gnupg
ssh root@localhost -i $SSH_KEY -p $SSH_PORT "chmod 700 /repo/gnupg /root/.gnupg && chown -R root:root /root/.gnupg /repo/gnupg"
ssh root@localhost -i $SSH_KEY -p $SSH_PORT "sed -i \"s/YOUR_GPG_KEY_ID/$GPG_KEY_ID/g\" /repo/conf/distributions"
ssh root@localhost -i $SSH_KEY -p $SSH_PORT "sed -i \"s/YOUR_GPG_KEY_ID/$GPG_KEY_ID/g\" /repo/gnupg/gpg_sign_key_id"
ssh root@localhost -i $SSH_KEY -p $SSH_PORT "sed -i \"s/YOUR_REPO_NAME/$REPO_NAME/g\" /repo/conf/distributions"
ssh root@localhost -i $SSH_KEY -p $SSH_PORT "sed -i \"s/YOUR_REPO_NAME/$REPO_NAME/g\" /repo/conf/incoming"

# Copy test packages
scp -i $SSH_KEY -P $SSH_PORT $SRC/*.deb $SRC/*.changes root@localhost:/repo/incoming
ssh root@localhost -i $SSH_KEY -p $SSH_PORT "repo-process-incoming $REPO_NAME"

# If we want a full test
if [[ "$1" == "--full" ]]; then
  cat ./test/public/my-repo.gpg.key | sudo apt-key add -
  sudo sh -c 'echo "deb http://localhost:34080 '${REPO_NAME}' main" > /etc/apt/sources.list.d/wolfetti-docker-reprepro-dev.list'
  sudo apt-get update
  sudo apt-get install docker-reprepro-test-package
  exec wolfetti-docker-reprepro-test
fi
