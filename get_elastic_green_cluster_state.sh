#!/bin/bash
#
# Author : James Lomprez
# Date : 15/07/2024

# Usage
ghelp()
{
printf "DESCRIPTION:
        Wait for cluster to be in yellow or green state

        SYNTAX:
        -s server_url -a apikey

        EXAMPLE:
        -s https://elastic-teos-ppd.intranet.geodis.org -a XXXXXXXXXXX"
}

while getopts "s:a:" OPTIONS; do
    case $OPTIONS in
         s ) ELKURL=$OPTARG;;
         a ) APIKEY=$OPTARG;;
         * )  ghelp
              exit 1
              ;;
    esac
done

if [ -z "${APIKEY}" ] || [ -z "${ELKURL}" ]
then
    ghelp
    exit 2
fi

state=$(curl -s -X GET "$ELKURL/_cluster/health?pretty" -H "Authorization: ApiKey $APIKEY" | awk 'NR == "3" {print $3}' | sed 's/[",]//g')

if [ $? -ne 0 ]; then
        echo "Error: Failed to connect to the server."
        exit 1
fi

while [[ "$state" != "green" ]]; do

   sleep 30
   state=$(curl -s -X GET "$ELKURL/_cluster/health?pretty" -H "Authorization: ApiKey $APIKEY" | awk 'NR == "3" {print $3}' | sed 's/[",]//g')

done

echo "The cluster state is in $state"

exit 0
