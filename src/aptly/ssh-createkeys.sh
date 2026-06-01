#!/bin/bash
#
# Generate sshd host keys on first boot (the Dockerfile strips the image-baked
# ones so every deployment gets its own). Strong keys only:
#   - ed25519           : modern, fast, the preferred host key in our hardened
#                         sshd_config. This is what clients will actually use.
#   - rsa 4096          : fallback for any client that can't do ed25519
#                         (rsa-sha2-512/256 — never ssh-rsa/SHA-1).
# No ECDSA: it's a NIST-P curve (the weakest of the three and de-prioritised in
# our HostKeyAlgorithms); ed25519 covers the same role better.

set -u

gen() {
    # gen <file> <ssh-keygen args...>  — only if absent.
    local file="$1"; shift
    [ -f "$file" ] && return 0
    ssh-keygen -q -t "$@" -f "$file" -N '' -C "aptly-$(hostname)-$(date +%Y%m%d)"
    command -v restorecon >/dev/null 2>&1 && restorecon "$file" "$file.pub" 2>/dev/null
    chmod 600 "$file"; chmod 644 "$file.pub"
    ssh-keygen -l -f "$file.pub"
}

gen /etc/ssh/ssh_host_ed25519_key ed25519
gen /etc/ssh/ssh_host_rsa_key     rsa -b 4096
