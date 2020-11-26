#!/macports/bin/bash

#
#           --manual-auth-hook /path/to/dns/authenticator.sh \
#

#
#   uncomment these for feedback / test
#
#echo "CERTBOT_DOMAIN      : ${CERTBOT_DOMAIN}"     1>&2
#echo "CERTBOT_VALIDATION  : ${CERTBOT_VALIDATION}" 1>&2

declare -i dnssleep=300

. ./login.incl

#
#   opret TXT record
curl \
    --silent \
    -c ../download/cookies.txt \
    -b ../download/cookies.txt \
    -F user_domain=${DOMAIN} \
    -F name=_acme-challenge.${CERTBOT_DOMAIN} \
    -F txtdata=${CERTBOT_VALIDATION} \
    -F ttl=300 \
    -F action=dns_primary_record_added_txt \
    -L \
    --output ../download/gratisdns.html \
    --url 'https://admin.gratisdns.com/'

#
#   tjek at det er gået godt
tidy -q -asxml --numeric-entities yes ../download/gratisdns.html 2>/dev/null > ../download/gratisdns.xml
domCount=$( \
    xpath ../download/gratisdns.xml '//td[@class="table-success"]' 2>&1 \
    | sed -E -e '1,2d' \
    | wc -l )
if [[ ! ${domCount} -eq 1 ]]
then
    fejlTekst=$( xpath ../download/gratisdns.xml '//td[@class="table-danger"]/text()' 2>/dev/null )
    echo "fejl i oprettelsen af TXT record : ${fejlTekst}" 1>&2
    exit 1
fi

#
#   find id på TXT record
declare -A keyValues

while read -u 8 key value
do
    keyValues[${key}]=${value}
done 8< <( \
while read -u 9 keyValue 
do
    echo "${keyValue}"
done 9< <( \
xpath ../download/gratisdns.xml \
    "//text()[.=\"${CERTBOT_VALIDATION}\"]/../..//a[contains(@href,\"dns_primary_delete_txt\")]/@href" \
    2>&1 \
| sed -E -e '1,2d' \
| sed -E -e 's!\&amp\;!\&!g' -e 's!\?!!' -e 's!^.*"(.*)".*$!\1!' \
| tr '&' "\n"
) | tr '=' ' ' )

#
#   return
sleep ${dnssleep}
echo "${keyValues['id']}"
