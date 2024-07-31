#!/bin/bash

# find PID of ELK
PID="$(ps -ef | grep -i elastic | grep -v grep | awk 'NR == "1" {print $2}')"
OOM_ADJ_file="/proc/$PID/oom_adj"

if [[ -z  "${PID}" ]] && [[  "${PID}" =~ ^[0-9]+$ ]]
then
        echo pas de pid pour proc ELK
        exit 1
else
        echo ELK pid is $PID

fi

#Disable OOM Killer for the process


if [[ -e "${OOM_ADJ_file}" ]]
then
        echo -17 > "${OOM_ADJ_file}"
else
        echo file to disable oom_killer not found
        exit 1
fi

#check if omm killer is equal to zero

OOM_SCORE="$(cat /proc/$PID/oom_score)"

if [ "${OOM_SCORE}" == 0 ]
then
        echo OK oom_killer for  $PID is disabled because set to $OOM_SCORE
else
        echo $PID is NOT disabled because set to $OOM_SCORE
        exit 1
fi

exit 0
