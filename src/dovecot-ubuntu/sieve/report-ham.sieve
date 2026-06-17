# imapsieve: fires when a message is moved OUT of Junk (false positive rescued by
# the user). Pipes a copy to drp-report, which revokes it as HAM where supported
# (Razor/Pyzor; DCC has no network un-report). `:copy` leaves the move untouched.
# `:copy` comes from the copy extension, so it must be required alongside
# vnd.dovecot.pipe (the build-time sievec precompile needs copy loaded for it).
require ["vnd.dovecot.pipe", "copy"];

pipe :copy "drp-report" ["revoke"];
