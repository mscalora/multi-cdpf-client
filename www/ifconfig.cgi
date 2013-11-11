#! /bin/bash
echo "Content-type: text/html"
echo ""
echo "<h3>ifconfig</h3><pre>"

ifconfig | tail -n 90

echo "</pre><hr/><h3>wpa_supplicant.conf</h3><pre>"

sudo cat /etc/wpa_supplicant/wpa_supplicant.conf

echo "</pre><p><a href='/'>Home</a></p>"