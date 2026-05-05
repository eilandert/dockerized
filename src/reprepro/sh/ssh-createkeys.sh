#!/bin/bash

host_keys_required() {
    echo /repo/ssh/ssh_host_rsa_key
    echo /repo/ssh/ssh_host_dsa_key
    echo /repo/ssh/ssh_host_ecdsa_key
    echo /repo/ssh/ssh_host_ed25519_key
}

create_key() {
    msg="$1"
    shift
    hostkeys="$1"
    shift
    file="$1"
    shift

    if echo "$hostkeys" | grep -x "$file" >/dev/null && \
        [ ! -f "$file" ] ; then
        printf %s "$msg"
        ssh-keygen -q -f "$file" -N '' "$@"
        echo
        if which restorecon >/dev/null 2>&1; then
            restorecon "$file" "$file.pub"
        fi
        ssh-keygen -l -f "$file.pub"
    fi
}

create_keys() {
    hostkeys="$(host_keys_required)"
    if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
        create_key "Creating SSH2 RSA key; this may take some time ..." \
            "$hostkeys" /repo/ssh/ssh_host_rsa_key -t rsa
    fi
    if [ ! -f "/etc/ssh/ssh_host_dsa_key" ]; then
        create_key "Creating SSH2 DSA key; this may take some time ..." \
            "$hostkeys" /repo/ssh/ssh_host_dsa_key -t dsa
    fi
    if [ ! -f "/etc/ssh/ssh_host_ecdsa_key" ]; then
        create_key "Creating SSH2 ECDSA key; this may take some time ..." \
            "$hostkeys" /repo/ssh/ssh_host_ecdsa_key -t ecdsa
    fi
    if [ ! -f "/etc/ssh/ssh_host_ed25519_key" ]; then
        create_key "Creating SSH2 ED25519 key; this may take some time ..." \
            "$hostkeys" /repo/ssh/ssh_host_ed25519_key -t ed25519
    fi
}

create_keys
