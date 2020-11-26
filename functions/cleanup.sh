#!/macports/bin/bash

#
#           --manual-cleanup-hook /path/to/dns/cleanup.sh \
#

#
#   uncomment these for feedback / test
#
#echo "CERTBOT_DOMAIN      : ${CERTBOT_DOMAIN}"         1>&2
#echo "CERTBOT_VALIDATION  : ${CERTBOT_VALIDATION}"     1>&2
#echo "CERTBOT_AUTH_OUTPUT : ${CERTBOT_AUTH_OUTPUT}"    1>&2

[[ -z "${CERTBOT_AUTH_OUTPUT}" ]] && exit

. ./login.incl

#
#   slet TXT record
curl \
    --silent \
    -c ../download/cookies.txt \
    -b ../download/cookies.txt \
    -F user_domain=${DOMAIN} \
    -F id=${CERTBOT_AUTH_OUTPUT} \
    -F action=dns_primary_delete_txt \
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
    echo "fejl i sletningen af TXT record : ${fejlTekst}" 1>&2
    exit 1
fi

#
# genstart apache2

# my customised MacOS 10.6
~bjarne/Sites/bin/apachectl restart

# linux
# systemctl reload apache2


