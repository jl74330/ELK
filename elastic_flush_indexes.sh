#!/bin/bash
#
# Author : James Lomprez
# Date : 17/07/2024

# Usage
ghelp()
{
printf "DESCRIPTION:
        Flushes indexes for elastic

        SYNTAX:
        -s server_url -a apikey

        EXAMPLE:
        -s https://elastic-fqdn.org -a XXXXXXXXXXX"
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

# Execute curl
response=$(curl -s -X POST "$ELKURL/_flush/?pretty" -H "Content-Type: application/json" -H "Authorization: ApiKey $APIKEY")

if [ $? -ne 0 ]; then
        echo "Error: Failed to connect to the server."
        exit 1
fi

# Parse the JSON response to check if failed flushed indexes
output=$(echo $response | jq '.failed')

while [[ "$output" -ne 0 ]] ; do

    sleep 30
    $output=$(curl -s -X POST "$ELKURL/_flush/?pretty" -H "Content-Type: application/json" -H "Authorization: ApiKey $APIKEY" | jq '.failed')

done

echo "All indexes flushed, no failed"
  exit 0
