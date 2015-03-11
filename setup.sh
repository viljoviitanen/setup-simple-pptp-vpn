#!/bin/sh
#    Setup Simple PPTP VPN server for Ubuntu and Debian
#    Copyright (C) 2013-2014 Viljo Viitanen <viljo.viitanen@iki.fi> and contributors
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#    2013-11-06: initial version. Tested with Amazon EC2 Ubuntu 12.04 and 
#                Digital Ocean Debian 7.0 and Ubuntu 12.04 images.
#    2014-03-23: Added apt-get update.

printhelp() {

echo "

Usage: sh setup.sh [OPTION]

If you are using custom password , Make sure its more than 8 characters. Otherwise it will generate random password for you. 

If you trying set password only. It will generate Default user with Random password. 

example: sudo bash setup.sh -u vpn -p

Use without parameter [ sudo bash setup.sh ] to use default username and Random password


  -u,    --username             Enter the Username
  -p,    --password             Enter the Password when prompted
"
}

while [ "$1" != "" ]; do
  case "$1" in
    -u    | --username )             NAME=$2; shift 2 ;;
    -p    | --password )             stty_orig=`stty -g`; stty -echo; read -p "Enter preferred password: " PASS; stty $stty_orig; echo ""; break ;;
    -h    | --help )                echo "$(printhelp)"; exit; shift; break ;;
  esac
done

if [ `id -u` -ne 0 ] 
then
  echo "Need root, try with sudo"
  exit 0
fi

echo "Making sure apt-get is updated..."
apt-get update > /dev/null

echo "Installing pptpd..."
apt-get -y install pptpd > /dev/null || {
  echo "Could not install pptpd" 
  exit 1
}

#ubuntu has exit 0 at the end of the file.
sed -i '/^exit 0/d' /etc/rc.local

cat >> /etc/rc.local << END
echo 1 > /proc/sys/net/ipv4/ip_forward
#control channel
iptables -I INPUT -p tcp --dport 1723 -j ACCEPT
#gre tunnel protocol
iptables -I INPUT  --protocol 47 -j ACCEPT

iptables -t nat -A POSTROUTING -s 192.168.2.0/24 -d 0.0.0.0/0 -o eth0 -j MASQUERADE

#supposedly makes the vpn work better
iptables -I FORWARD -s 192.168.2.0/24 -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j TCPMSS --set-mss 1356

END
sh /etc/rc.local

#no liI10oO chars in password

LEN=$(echo ${#PASS})

if [ -z "$PASS" ] || [ $LEN -lt 8 ] || [ -z "$NAME"]
then
   P1=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
   P2=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
   P3=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
   PASS="$P1-$P2-$P3"
fi

if [ -z "$NAME" ]
then
   NAME="vpn"
fi

cat >/etc/ppp/chap-secrets <<END
# Secrets for authentication using CHAP
# client server secret IP addresses
$NAME pptpd $PASS *
END
cat >/etc/pptpd.conf <<END
option /etc/ppp/options.pptpd
logwtmp
localip 192.168.2.1
remoteip 192.168.2.10-100
END
cat >/etc/ppp/options.pptpd <<END
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4
proxyarp
lock
nobsdcomp 
novj
novjccomp
nologfd
END

apt-get -y install wget || {
  echo "Could not install wget, required to retrieve your IP address." 
  exit 1
}

#find out external ip 
IP=`wget -q -O - http://api.ipify.org`

service pptpd restart

clear

if [ "x$IP" = "x" ] ; then
  NO_IP=true
  echo "============================================================"
  echo "  !!!  COULD NOT DETECT SERVER EXTERNAL IP ADDRESS  !!!"
  echo "  !!!  Please manually find out your server's       !!!"
  echo "  !!!  external IP address before connecting!       !!!"
else
  NO_IP=false
  echo "============================================================"
  echo "Detected your server external ip address: $IP"
fi
echo   ""
echo   "VPN username = $NAME   password = ********"
echo   "============================================================"

echo "Your VPN server password is hidden. Would you like to reveal it?"
while true; do
  read -p "" yn
  case $yn in
      [Yy]* ) clear; break;;
      [Nn]* ) exit 0;;
      * ) echo "Please answer with yes or no [y|n].";;
  esac
done

if [ $NO_IP = "true" ] ; then 
  echo "============================================================"
  echo "  !!!  COULD NOT DETECT SERVER EXTERNAL IP ADDRESS  !!!"
  echo "  !!!  Please manually find out your server's       !!!"
  echo "  !!!  external IP address before connecting!       !!!"
  echo ""
  echo "VPN username = $NAME   password = $PASS"
  echo "============================================================"
else
  echo "============================================================"
  echo "Detected your server external ip address: $IP"
  echo ""
  echo "VPN username = $NAME   password = $PASS"
  echo "============================================================"
fi

sleep 1

exit 0