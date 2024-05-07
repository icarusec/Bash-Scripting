#!/bin/bash

# Author: [username]
# Script: Bug Bounty Recon
# Function: Bug Bounty Reconnaissance shell script.

# Set the debug mode to print each command before executing it
set -x 

# Define the base directory for bug bounty data
bbloc=/home/[username]/Bug_bounty/

# Define the directory for Go binaries

# Define the target domain
target=$1
echo "Please enter the name of the company:"
read company_name

# Create the directory for the target
target_dir=${bbloc}${target}
mkdir -p ${target_dir}

# Create subdirectories for different types of data
mkdir -p ${target_dir}/subdomains
mkdir -p ${target_dir}/endpoints
mkdir -p ${target_dir}/apis
mkdir -p ${target_dir}/screenshots
mkdir -p ${target_dir}/dorks
mkdir -p ${target_dir}/s3

# Create necessary files with appropriate permissions
touch "${target_dir}/Readme.md"
chmod 666 "${target_dir}/Readme.md"

touch ${target_dir}/subdomains/consolidated.txt
chmod 666 ${target_dir}/subdomains/consolidated.txt

touch ${target_dir}/endpoints/${target}.txt
chmod 666 ${target_dir}/endpoints/${target}.txt

touch ${target_dir}/endpoints/all.txt
chmod 666 ${target_dir}/endpoints/all.txt

# Subdomain Enumeration
# Sublist3r
echo "Enumerating subdomains using Sublist3r"
cd /home/[username]/Sublist3r/
python3 sublist3r.py -d "${target}" -v -o ${target_dir}/subdomains/${target}_sublister.txt
chmod 666 ${target_dir}/subdomains/${target}_sublister.txt

# Assetfinder
echo "Enumerating subdomains using Assetfinder"
assetfinder "${target}" >> ${target_dir}/subdomains/${target}_assetfinder.txt
chmod 666 "${target_dir}/subdomains/${target}_assetfinder.txt"

# crt.sh
echo "Scraping subdomains from crt.sh"
curl -s "https://crt.sh/?q=%.${target}" | grep "${target}" | grep TD | sed -e 's/<//g' | sed -e 's/>//g' | sed -e 's/TD//g' | sed -e 's/\///g' | sed -e 's/ //g' | sed -n '1!p' | sort -u > ${target_dir}/subdomains/${target}_crt.txt
chmod 666 ${target_dir}/subdomains/${target}_crt.txt

# Subfinder
echo "Enumerating subdomains using Subfinder"
subfinder -all -d "${target}" -o "${target_dir}/subdomains/${target}_subfinder.txt"
chmod 666 ${target_dir}/subdomains/${target}_subfinder.txt

# SubDomainizer
echo "Enumerating subdomains using SubDomainizer"
cd /home/[username]/SubDomainizer
python3 /usr/bin/SubDomainizer.py -u "https://${target}" -o ${target_dir}/subdomains/${target}_subdomainizer.txt
chmod 666 ${target_dir}/subdomains/${target}_subdomainizer.txt

# Sudomy
echo "Enumerating subdomains using Sudomy"
cd /home/[username]/Sudomy/
sudomy -d "${target}" -eP -tO -gW --dnsx --no-probe -o ${target_dir}/subdomains/

# Subdomain Consolidation
cd ${target_dir}/subdomains
cat "${target}_sublister.txt" >> consolidated.txt
cat "${target}_assetfinder.txt" >> consolidated.txt
cat "${target}_crt.txt" >> consolidated.txt
cat "${target}_subfinder.txt" >> consolidated.txt
cat "${target}_subdomainizer.txt" >> consolidated.txt
cat "${target}_sudomy.txt" >> consolidated.txt

sort -u -o ${target_dir}/subdomains/all.txt consolidated.txt
chmod 666 ${target_dir}/subdomains/all.txt

#searching for s3 buckets
cat all.txt | grep "s3" >> ${target_dir}/s3/s3-buckets.txt


# Probing for Alive Subdomains
httpx -l "${target_dir}/subdomains/all.txt" -o ${target_dir}/subdomains/alive.txt -threads 200 -follow-redirects
chmod 666 ${target_dir}/subdomains/alive.txt

# Checking for Subdomain Takeovers
echo "Checking for Subdomain Takeovers"
cd /home/[username]/sub404/
python3 sub404.py -f ${target_dir}/subdomains/alive.txt

# Screenshots of Alive Subdomains
echo "Taking screenshots of alive subdomains"
mkdir -p "${target_dir}/screenshots"
chmod 777 "${target_dir}/screenshots"
gowitness file -f "${target_dir}/subdomains/alive.txt" --screenshot-path "${target_dir}/screenshots/"
cd $goloc

# Endpoint Enumeration
echo "Enumerating endpoints using Gospider"
gospider -S ${target_dir}/subdomains/alive.txt -c 10 -d 1 -t 10 -o ${target_dir}/endpoints/${target}_gospider.txt >/dev/null 2>&1
chmod 666 "${target_dir}/endpoints/${target}_gospider.txt"

echo "Enumerating endpoints from JS Files using GoLinkFinder"
touch "${target_dir}/endpoints/${target}_golinkfinder.txt"
chmod 666 ${target_dir}/endpoints/${target}_golinkfinder.txt
GoLinkFinder -d ${target} -o ${target}_endpoints_golinkfinder.txt >/dev/null 2>&1
mv ${target}_endpoints_golinkfinder.txt ${target_dir}/endpoints/

echo "Enumerating URLs from Waybackurls"
waybackurls $target > ${target_dir}/endpoints/${target}_urls_wayback.txt
gau --o $target_dir/endpoints/${target}_urls_gau.txt $target
chmod 666 ${target_dir}/endpoints/${target}_urls_wayback.txt

cd $target_dir/endpoints
cat ${target}_urls_gau.txt >> endpoints_unsanitised.txt
cat ${target}_endpoints_gospider.txt >> endpoints_unsanitised.txt
cat ${target}_endpoints_golinkfinder.txt >> endpoints_unsanitised.txt
cat ${target}_urls_wayback.txt >> endpoints_unsanitised.txt
xurls $target_dir/endpoints/endpoints_unsanitised.txt > endpoints.txt
mv endpoints.txt ${target_dir}/endpoints/
sort -u -o endpoints.txt endpoints.txt


cat "${target}_urls_gau.txt" "${target}_urls_wayback.txt" | sort -u > gauway-urls.txt
cat gauway-urls.txt | qsreplace FUZZ > ${target_dir}/endpoints/gauway-urls-fuzz.txt
grep 'FUZZ' ${target_dir}/gauway-urls-fuzz.txt >> ${target_dir}/endpoints/gauway-urls-final.txt


grep -oP '(?<=https://github.com/).*?(?=/)' endpoints.txt >> github_repos.txt
chmod 666 ${target_dir}/github_repos.txt

sort -u -o ${target_dir}/endpoints/all.txt endpoints.txt
chmod 666 ${target_dir}/endpoints/all.txt
echo "Endpoints Found"

# API Endpoint Enumeration
touch ${target_dir}/apis/endpoints.txt
chmod 666 ${target_dir}/apis/endpoints.txt
cat ${target_dir}/endpoints/all.txt | grep "api" >> ${target_dir}/apis/endpoints.txt
echo "Listed API Endpoints"
cat ${target_dir}/apis/endpoints.txt
cat ${target_dir}/endpoints/all.txt | grep "s3" >> ${target_dir}/s3/s3-buckets.txt
cat ${target_dir}/s3/s3-buckets.txt

# Google Dorking
echo "Google Dorking for Wordpress API users"
go-dork -q "inurl:\"/wp-json/wp/v2/users\" site:*.${target}" -p 3 >> ${target_dir}/dorks/wpapiuser.txt
chmod 666 ${target_dir}/apis/wpapiuser.txt

echo "Google Dorking for Public API keys"
go-dork -q "intitle:\"index.of\" intext:\"api.txt\" site:*.${target}" -p 3 >> ${target_dir}/dorks/publicapikeys.txt
chmod 666 ${target_dir}/apis/publicapikeys.txt

echo "Google Dorking for API directories"
go-dork -q "inurl:\"/api/v1\" intext:\"index of /\" site:*.${target}" -p 3 >> ${target_dir}/dorks/apidirectories.txt
chmod 666 ${target_dir}/apis/apidirectories.txt

echo "Google Dorking for Zen API SQLI Vulnerability"
go-dork -q "ext:php inurl:\"api.php?action=\" site:*.${target}" -p 3 >> ${target_dir}/dorks/zenapisqlivuln.txt
chmod 666 ${target_dir}/apis/zenapisqlivuln.txt

echo "Google Dorking for Wordpress config files"
go-dork -q "inurl:\"wp-config.php\" site:*.${target}" -p 3 >> ${target_dir}/dorks/wpconfigfiles.txt
chmod 666 ${target_dir}/dorks/wpconfigfiles.txt

echo "Google Dorking for Database files"
go-dork -q "ext:sql intext:\"INSERT INTO\" site:*.${target}" -p 3 >> ${target_dir}/dorks/databasefiles.txt
chmod 666 ${target_dir}/dorks/databasefiles.txt

echo "Google Dorking for Backup and old files"
go-dork -q "intitle:\"index of\" intext:\"backup\" site:*.${target}" -p 3 >> ${target_dir}/dorks/backupfiles.txt
chmod 666 ${target_dir}/dorks/backupfiles.txt

echo "Google Dorking for Login pages"
go-dork -q "inurl:\"login\" site:*.${target}" -p 3 >> ${target_dir}/dorks/loginpages.txt
chmod 666 ${target_dir}/dorks/loginpages.txt

echo "Google Dorking for SQL errors"
go-dork -q "intext:\"sql syntax near\" site:*.${target}" -p 3 >> ${target_dir}/dorks/sqlerrors.txt
chmod 666 "${target_dir}/dorks/sqlerrors.txt"

echo "Google Dorking for PHP info"
go-dork -q "ext:php intitle:phpinfo \"published by the PHP Group\" site:*.${target}" -p 3 >> ${target_dir}/dorks/phpinfo.txt
chmod 666 ${target_dir}/dorks/phpinfo.txt

echo "Google Dorking for: site:http://s3.amazonaws.com intitle:index.of.bucket \"$target\""
go-dork -q "site:http://s3.amazonaws.com intitle:index.of.bucket \"$target\"" -p 3 >> ${target_dir}/s3/s3-buckets.txt

echo "Google Dorking for: site:http://amazonaws.com inurl:\".s3.amazonaws.com/\" \"$target\""
go-dork -q "site:http://amazonaws.com inurl:\".s3.amazonaws.com/\" \"$target\"" -p 3 >> ${target_dir}/s3/gs3-buckets.txt

echo "Google Dorking for: site:.s3.amazonaws.com \"$target\""
go-dork -q "site:.s3.amazonaws.com \"$target\"" -p 3 >> ${target_dir}/s3/s3-buckets.txt

#extracting bucket names
grep -oE '(?!(^xn--|.+-s3alias$))^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$' ${target_dir}/s3/gs3-buckets.txt > ${target_dir}/s3/s3-bucket-names.txt


#Checking for open s3 buckets
echo "Checking for open s3 bucekts"
s3scanner -bucket-file ${target_dir}/s3/s3-buckets.txt -enumerate

# XSS Automation
echo "Adding FUZZing Variable to the Endpoints"
cat ${target_dir}/endpoints/all.txt | qsreplace "FUZZ" > ${target_dir}/endpoints/xss.txt
chmod 666 "${target_dir}/endpoints/xss.txt"
grep 'FUZZ' ${target_dir}/endpoints/xss.txt >> ${target_dir}/endpoints/FUZZ_xss.txt
sort -u -o ${target_dir}/endpoints/all_xss.txt ${target_dir}/endpoints/FUZZ_xss.txt
dalfox file ${target_dir}/endpoints/gauway-urls-final.txt

# Screenshots of Alive Subdomains
echo "Screenshotting Alive subdomains"
mkdir -p ${target_dir}/screenshots
chmod 777 ${target_dir}/screenshots
gowitness file -f ${target_dir}/subdomains/alive.txt --screenshot-path ${target_dir}/screenshots/

# Fuzzing for s3 buckets
echo "Fuzzing for s3 Buckets"
cd /home/[username]/lazys3/
ruby lazys3.rb $company >> $target_dir/s3/lazy-enum.txt


echo "Reconnaissance complete"

