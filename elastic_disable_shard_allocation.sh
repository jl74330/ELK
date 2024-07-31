#!/bin/bash
#
# Author : James Lomprez
# Date : 16/07/2024

# Usage
ghelp()
{
printf "DESCRIPTION:
        Disable shard allocation for elastic

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

# Execute curl
response=$(curl -s -X PUT "$ELKURL/_cluster/settings?pretty" -H "Content-Type: application/json" -H "Authorization: ApiKey $APIKEY" -d '{
  "persistent": {
    "cluster.routing.allocation.enable": "primaries"
  }
}')

# Parse the JSON response to check for acknowledged: true
output=$(echo $response | jq '.acknowledged')

# Check if acknowledged is true
if [ "$output" == "true" ]; then
  echo "Operation acknowledged: true, shard allocation disabled"
  exit 0
else
  echo "Operation failed or not acknowledged"
  exit 1
fi
