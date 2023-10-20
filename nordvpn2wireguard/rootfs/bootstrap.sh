#!/bin/bash

nord_login && nord_config && nord_connect && nord_migrate && nord_watch

my_interface=$(wg show | grep interface | cut -d" " -f2)
my_privkey=$(wg show $my_interface private-key)
my_ip=$(ip -f inet addr show $my_interface  | awk '/inet/ {print $2}')

read host ip city country serv_pubkey < <( echo $(curl -s "https://api.nordvpn.com/v1/servers/recommendations?&filters\[servers_technologies\]\[identifier\]=wireguard_udp&limit=1" | jq -r '.[]|.hostname, .station, (.locations|.[]|.country|.city.name), (.locations|.[]|.country|.name), (.technologies|.[].metadata|.[].value)'))

sid=$(echo $host | cut -d. -f1)
fn="nvpn_"$sid".conf"
echo Server: $host \($ip\) has pubkey $serv_pubkey

echo writing config to $fn
echo "#config for nordvpn server $sid"  > $fn
echo "[Interface]"                      >> $fn
echo "Address = $my_ip"                  >> $fn
echo "PrivateKey = $my_privkey"            >> $fn
echo ""                                 >> $fn
echo "[Peer]"                           >> $fn
echo "PublicKey = $serv_pubkey"         >> $fn
echo "AllowedIPs = 0.0.0.0/0"           >> $fn
echo "Endpoint = $host:51820"           >> $fn

echo ""
echo "Content of $fn:"
cat $fn

qrencode -t ansiutf8 < $fn



