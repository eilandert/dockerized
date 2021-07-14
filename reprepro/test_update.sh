#!/bin/bash
SSH_PORT=34022
SSH_KEY="$(pwd)/test/ssh/test_id_rsa"
ssh root@localhost -i $SSH_KEY -p $SSH_PORT repo-update-mirrors
