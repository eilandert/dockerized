# imapsieve: fires when a message is moved/copied INTO Junk. Pipes a copy of the
# message to drp-report, which reports it as SPAM to DCC/Razor/Pyzor.
# `:copy` so the IMAP operation itself is untouched.
require ["vnd.dovecot.pipe"];

pipe :copy "drp-report" ["report"];
