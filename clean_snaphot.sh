#!/bin/bash

# Usage
ghelp()
{
printf "DESCRIPTION:
        Clean elasticsearch snapshot

SYNTAX:
        $0 -h elasticsearch_server_name -p token

EXEMPLE:
        $0 -h elastic.lonnfo.net -p XXX-XXX-XXX-XXXX

"
}

command -v jq >/dev/null 2>&1

if [ $? != 0 ]
then
        echo "jq not found"
    exit
fi

while getopts "h:p:" OPCIONES; do
    case $OPCIONES in
         h ) ESSERVER=$OPTARG;;
         p ) APIKEY=$OPTARG;;
         * )  ghelp
              exit 1
              ;;
    esac
done

if [ -z "${APIKEY}" ] || [ -z "${ESSERVER}" ]
then
    ghelp
    exit 2
fi

DATE_RETENTION=$(date -d "-7 days" +"%Y%m%d")
LIST_SNAPSHOT=$(curl -XGET -H "Authorization: ApiKey $APIKEY" "https://$ESSERVER/_snapshot/my_backup/snapshot_*" 2>/dev/null)

for I in `echo $LIST_SNAPSHOT | jq -r '.snapshots |.[] |.snapshot'`
do
    SNAPSHOT_END_TIME=$(echo $LIST_SNAPSHOT | jq -r '.snapshots |.[] | select(.snapshot=="'$I'") |.end_time')
    SNAPSHOT_END_TIME=$(date -d $SNAPSHOT_END_TIME +"%Y%m%d")
    if [ $SNAPSHOT_END_TIME -lt $DATE_RETENTION ]
    then
        echo $I "to be delete"
        curl -X DELETE  -H "Authorization: ApiKey $APIKEY" "https://$ESSERVER/_snapshot/my_backup/$I?pretty" 2>/dev/null # | jq -r '.status'
    fi
done
