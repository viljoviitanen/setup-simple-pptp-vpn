Setup Simple PPTP VPN server for Ubuntu and Debian
==================================================

> NOTE: PPTP VPN is considered insecure. Do not rely for this vpn
> if you need security. The security of the VPN can probably
> be cracked with any serious attacker. See
> http://en.wikipedia.org/wiki/Point-to-Point_Tunneling_Protocol#Security
> If you need security, consider using e.g. openvpn, you can setup a server
> easily with https://github.com/viljoviitanen/setup-simple-openvpn

Script has been tested on Amazon EC2: Ubuntu Server 12.04.3 LTS

Digital Ocean: Ubuntu 12.04 LTS (Precise Pangolin), Debian 7 (Wheezy)

Copyright 2013 Viljo Viitanen <viljo.viitanen@iki.fi>
Licensed under GPL version 2 or any later version.

INSTALLATION INSTRUCTIONS
=========================

Amazon EC2
----------

Allow the following through the firewall ("security group")
- ICMP (all)
- TCP port 22 (SSH)
- TCP port 1723

Common
------

    wget https://raw.github.com/viljoviitanen/setup-simple-pptp-vpn/master/setup.sh
    sudo sh setup.sh

Let the script run. Take note if the server external ip address
detection is succesful.  

Get your computer to use the VPN. Try googling for instructions, e.g.
https://www.google.com/#q=setup+pptp+windows+8

> Note: at least on Ubuntu Desktops and probably other Linuxes as well,
> you need to enable MPPE encryption from advanced settings!

Enjoy your very own (somewhat insecure) VPN!

Some notes
==========

Clients are configured to use Google public dns servers when
the vpn connection is active: https://developers.google.com/speed/public-dns/

Only one vpn account is generated.
To add more accounts, see the file /etc/ppp/chap-secrets

If you keep the vpn server generated with this script on the internet for a
long time (days or more), consider either restricting access to the ssh port on
the server by ip addresses to the networks you use, if you know the addresses
you are most likely to use or at least change ssh from port 22 to a random
port.
