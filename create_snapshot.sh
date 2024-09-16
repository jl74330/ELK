SCRIPT snapshot elastic

#!/bin/bash

DATE=$(date +"%Y%m%d")

# Usage
ghelp()
{
printf "DESCRIPTION:
	Create elasticsearch snapshot

SYNTAX:
	$0 -h elasticsearch_server_name -p token

EXEMPLE:
	$0 -h elastic.jlonnfo.net -p XXX-XXX-XXX-XXXX

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

SNAPSHOT_STATUS=$(curl -XGET -H "Authorization: ApiKey $APIKEY" "https://$ESSERVER/_snapshot/my_backup/snapshot_$DATE" 2>/dev/null)

if [ $(echo $SNAPSHOT_STATUS | jq -r '.status') == "null" ]
then
    echo $(echo $SNAPSHOT_STATUS | jq -r '.snapshots |.[] | .snapshot') "already exist"
    exit 2
fi

if [ $(echo $SNAPSHOT_STATUS | jq -r '.status') == "401" ]
then
    echo "missing authentication credentials for REST request"
    exit 2
fi

curl -X PUT -H "Authorization: ApiKey $APIKEY" "https://$ESSERVER/_snapshot/my_backup/snapshot_$DATE?pretty"

if [ $? != 0 ]
then  
    echo "ERROR: SNAPSHOT START FAILLED"  
    exit
fi 

# Wait until snapshot will be finish

COUNT=1  
MAX_RETRIES=60

while true; do
    # Check the state of the snapshot
    STATE=$(curl -XGET -H "Authorization: ApiKey $APIKEY" "https://$ESSERVER/_snapshot/my_backup/snapshot_$DATE" 2>/dev/null | jq -r '.snapshots | .[] | .state')

    if [ "$STATE" != "SUCCESS" ] && [ "$STATE" != "PARTIAL" ]; then
        COUNT=$((COUNT+1))

        # Check if retry count has reached the maximum
        if [ "$COUNT" -ge "$MAX_RETRIES" ]; then
            echo "Snapshot snapshot_$DATE did not succeed as expected after $MAX_RETRIES attempts. Exiting."
            exit 1
        fi

        sleep 10  # Wait for a bit before retrying
    else
        # If the snapshot state is "SUCCESS" or "PARTIAL", print the message and exit the loop
        echo "SNAPSHOT snapshot_$DATE state: $STATE"
        break
    fi
done
