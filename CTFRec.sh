#!/bin/bash

#-Bash Reconaissance script for use in CTFS

#-Functionalities
#   1. Fping check
#   2. Nmap Service port listing and Service Scanning
#   3. Automated Nikto Scan on Webservers
#   4. Automated Directory busting using Gobuster , checking for php , txt files 

#Run openvpn in background for tryhackme
#cd /home/icarusec/tryhackme/
#sudo openvpn parayilavinashp.ovpn &



#Colours
Red=$'\e[1;31m'
Green=$'\e[1;32m'
Orange=$'\e[1:33m'
Blue=$'\e[1;34m'
Purple=$'\e[1;35m'
White=$'\e[0m'

echo "███    ███ ██    ██     ███████ ██       █████   ██████      ██████  ██ ████████  ██████ ██   ██ ";
echo "████  ████  ██  ██      ██      ██      ██   ██ ██           ██   ██ ██    ██    ██      ██   ██ ";
echo "██ ████ ██   ████       █████   ██      ███████ ██   ███     ██████  ██    ██    ██      ███████ ";
echo "██  ██  ██    ██        ██      ██      ██   ██ ██    ██     ██   ██ ██    ██    ██      ██   ██ ";
echo "██      ██    ██        ██      ███████ ██   ██  ██████      ██████  ██    ██     ██████ ██   ██ ";
echo "                                                                                                 ";
echo "                                                                                                 ";
echo "                                                                                                 ";
echo "                                                                                                 ";
echo "                                                                                                 ";
echo "                                                                                                 ";
echo "                                                                                                 ";
echo "                                                                                               ";                                                                                         
#Directory Creation
cd /home/icarusec/tryhackme
read -p 'Directory Name:'$Green Dir 
	echo""
mkdir $Dir
cd $Dir
touch Readme.md

# Define target IP address
if [ $# -ne 1 ]; then
    echo "$Orange Usage: $0 <IP address>"
    exit 1
fi
target="$1"

# Check if target is alive using fping
#echo "Checking if target is alive..."
#if ! fping -c 1 $target > /dev/null 2>&1; then
#    echo "Target is not alive. Exiting..."
#    exit 1
#fi

# Perform Nmap scan to get open ports
echo "Performing Nmap scan to identify open ports"
sudo nmap -oX nmap.xml -sT $target 
ports=$(xmlstarlet sel -t -m '//port[state/@state="open"]' -v '@portid' -o ',' < nmap.xml)


# Perform service scan on open ports
echo "Performing service scan on identified ports"
sudo nmap -oX services.nmap -sV -sT -p $ports $target 

# Check if any HTTP servers are running
echo "Checking for HTTP servers"
http_ports=$(xmlstarlet sel -t -m '//port[service[@name="http"]]' -v '@portid' -n < nmap.xml)

if [ ! -z "$http_ports" ]; then
    echo "HTTP server(s) found on port(s): $http_ports"
    for port in $http_ports; do
        echo "Running Nikto scan on HTTP server(s) on port $port"
        nikto -h "http://$target:$port"
        echo "Finding base URL of the website using nslookup"
        echo "Base URL: $target"
        echo "Running directory busting tool on $base_url"
        gobuster dir -u "http://$target:$port" -w /usr/share/wordlists/rockyou.txt -x php,txt
    done
else
    echo "No HTTP servers found."
fi

echo "Reconnaissance completed."
