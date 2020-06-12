
Quick docker to run rbldnsd.

Compiled with alpine:edge and put in a SCRATCH container. Compiled from: https://github.com/rspamd/rbldnsd

It will start with a default set. 
Mount /zones and run with your own command to run other zonefiles.


Please don't use included zone, it's included for testing purposes. I gathered those sources long time ago for blocking with iptables.
I cannot support or guarantuee anything as I don't own the actual data nor can I remove ip's. I don't own the copyrights/licences either.

Sources of the default test-set, sorted and optimized with iprange

        http://www.cruzit.com/xwbl2txt.php
        http://www.darklist.de/raw.php
        https://www.badips.com/get/list/any/2?age=14d&format=ipset
        http://danger.rulez.sk/projects/bruteforceblocker/blist.php"
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/bi_any_2_7d.ipset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/bi_wordpress_1_7d.ipset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/blocklist_de.ipset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/botscout_30d.ipset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/bruteforceblocker.ipset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/cleanmx_phishing.ipset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/cleanmx_viruses.ipset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/cleantalk_top20.ipset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/cybercrime.ipset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/dshield_1d.netset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/dshield_30d.netset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/dshield_7d.netset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/dshield_top_1000.ipset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_abusers_1d.netset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_abusers_30d.netset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level3.netset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/greensnow.ipset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/iw_spamlist.ipset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/malwaredomainlist.ipset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/spamhaus_drop.netset
        https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/spamhaus_edrop.netset

