dockerized postfix based on debian:trixie and ubuntu:rolling with packages
from http://deb.myguard.nl

First-run behaviour: if `/etc/postfix/main.cf` does not exist, the image
populates `/etc/postfix/` from the baked-in `/etc/postfix.orig/`. When the
myguard postfix package ships `main.cf.proto` / `master.cf.proto`, those
are applied as the active config — that gives you:

- TLSv1.2+ floor (SSLv2/v3, TLSv1.0/v1.1 disabled)
- PFS-only cipher list (ECDHE/DHE + AEAD, no RSA-kex, RC4, 3DES, SHA1, etc.)
- Hybrid post-quantum KEM groups (X25519MLKEM768, SecP256r1MLKEM768) via
  `tls_eecdh_auto_curves` — requires OpenSSL ≥ 3.5; falls back to
  classical X25519 / P-256 / P-384 automatically
- `tls_ssl_options = NO_COMPRESSION, NO_RENEGOTIATION, NO_TICKET`
- smtpd anti-spoof + RFC-strict envelope restrictions
- connection cache + sensible concurrency defaults

To enable inbound TLS, add to `/etc/postfix/main.cf`:

    smtpd_tls_security_level = may
    smtpd_tls_chain_files = /path/to/key.pem, /path/to/fullchain.pem

See `/usr/share/postfix/main.cf.tls` (inside the image) for a complete
reference snippet with submission/SMTPS examples.

## Environment variables

| Variable      | Effect                                                   |
| ------------- | -------------------------------------------------------- |
| `TZ`          | container timezone (e.g. `Europe/Amsterdam`)             |
| `SYSLOG_HOST` | forward maillog to a remote syslog (UDP); stdout if unset |
| `MALLOC`      | `mimalloc` (default), `jemalloc`, or `none`              |

## Daily reload

A 24-hour `postfix reload` loop is started in the background so the
container picks up renewed certs / config drops without restart.
