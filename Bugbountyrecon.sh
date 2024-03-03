#!/bin/bash
echo "███    ███  ██████  ███    ██ ███████ ██    ██     ███    ███  █████  ██   ██ ███████ ██████  ";
echo "████  ████ ██    ██ ████   ██ ██       ██  ██      ████  ████ ██   ██ ██  ██  ██      ██   ██ ";
echo "██ ████ ██ ██    ██ ██ ██  ██ █████     ████       ██ ████ ██ ███████ █████   █████   ██████  ";
echo "██  ██  ██ ██    ██ ██  ██ ██ ██         ██        ██  ██  ██ ██   ██ ██  ██  ██      ██   ██ ";
echo "██      ██  ██████  ██   ████ ███████    ██        ██      ██ ██   ██ ██   ██ ███████ ██   ██ ";
echo "                                                                                              ";
echo "                                                                                              ";
echo "                                                                                              ";
echo "                                                                                              ";
echo "                                                                                              ";

set -x

#--Bug Bounty Recon Bash Script
#--Subdomain enumeration using Sublist3r,Amass,Assetfinder

#Colours
Red=$'\e[1;31m'
Green=$'\e[1;32m'
Orange=$'\e[1:33m'
Blue=$'\e[1;34m'
Purple=$'\e[1;35m'
White=$'\e[0m'

#Directory Creation
cd /home/icarusec/Bug_bounty
read -p 'Directory Name:'$Green Dir 
	echo""
mkdir $Dir
cd $Dir
touch Readme.md

# Define target IP address
if [ $# -ne 1 ]; then
    echo "$Orange Usage: $0 <domain>"
    exit 1
fi
target="$1"

#--Sub-Domain-Enumeration
#--Sublist3r
cd /home/icarusec/Sublist3r/
python3 sublist3r.py -d $1 -v -o /home/icarusec/Bug_bounty/$Dir/$1-sublister.txt

#--Assetfinder
cd /home/icarusec/go/bin
./assetfinder $1 >> /home/icarusec/Bug_bounty/$Dir/$1-assetfinderdomain.txt

#--crt.sh(Test Code that gets subdomains from certificate websites )
curl -s "https://crt.sh/?q=%.$1" > /tmp/curl.out
cat /tmp/curl.out | grep "$1" | grep TD | sed -e 's/<//g' | sed -e 's/>//g' | sed -e 's/TD//g' | sed -e 's/\///g' | sed -e 's/ //g' | sed -n '1!p' | sort -u > "/home/icarusec/Bug_bounty/$Dir/$1-crtsublist.txt"


#--subfinder
./subfinder -recursive -all -d $1 -o /home/icarusec/Bug_bounty/$Dir/$1-subfinderdomains.txt

#--subdomainizer
python3 SubDomainizer.py -u "https://$1" -o /home/icarusec/Bug_bounty/$Dir/$1-subdomainizer.txt

#--subdomain-consolidation
cd /home/icarusec/Bug_bounty/$Dir
touch $1-consolidateddomains.txt
cat $1-sublister.txt >> $1-consolidateddomains.txt
cat $1-assetfinderdomain.txt >> $1-consolidateddomains.txt
cat $1-crtsublist.txt >> $1-consolidateddomains.txt
cat $1-subfinderdomains.txt >> $1-consolidateddomains.txt
cat $1-subdomainizer.txt >> $1-consolidateddomains.txt
sort -u -o "$1-consolidateddomains.txt" "$1-consolidateddomains.txt"

#--Probing-for-alive-subdomains
httprobe < $1-consolidateddomains.txt > $1-alivedomains.txt

#--Screenshots of alive subdomains
cd /home/icarusec/go/bin
mkdir /home/icarusec/Bug_bounty/$Dir/Screenshots
eyewitness -f /home/icarusec/Bug_bounty/ninestars/ninestarsusa.com-alivedomains.txt -d /home/icarusec/Bug_bounty/ninestars/Screenshots

echo "Reconaiscance complete"
