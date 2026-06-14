# imapsieve: fires when a message is moved OUT of Junk (false positive rescued by
# the user). Pipes a copy to drp-report, which revokes it as HAM where supported
# (Razor/Pyzor; DCC has no network un-report). `:copy` leaves the move untouched.
require ["vnd.dovecot.pipe"];

pipe :copy "drp-report" ["revoke"];
