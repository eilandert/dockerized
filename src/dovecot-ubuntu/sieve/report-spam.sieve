# imapsieve: fires when a message is moved/copied INTO Junk. Pipes a copy of the
# message to drp-report, which reports it as SPAM to DCC/Razor/Pyzor.
# `:copy` so the IMAP operation itself is untouched. The `:copy` tag is provided
# by the copy extension, so it must be required alongside vnd.dovecot.pipe (the
# build-time sievec precompile only registers it when copy is explicitly loaded).
require ["vnd.dovecot.pipe", "copy"];

pipe :copy "drp-report" ["report"];
