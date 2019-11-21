#!/bin/bash

trigger_json=`cat /tmp/trigger.json`
# Name of the admin that's publishing a session
publishing_admin=`echo $trigger_json | jq -r .session.\"user-name\"`
#echo $publishing_admin

# Getting the allowed tag
allowed_tag=`echo $trigger_json | jq -r .\"custom-data\".\"allowed-tag\"`

number_of_allowed_tags=`echo $trigger_json |jq '.operations | (."modified-objects"[] | {"tags": ."new-object".tags[].name}), (."deleted-objects"[] | {"tags": .tags[].name}), (."added-objects"[] | {"tags": .tags[].name}) | select(.tags==$TAG_NAME) | length' --arg TAG_NAME "$allowed_tag"`

echo "NUM $allowed_tag $number_of_allowed_tags"
if [ $number_of_allowed_tags -gt 0 ]; then
        echo "{\"result\":\"success\", \"message\":\"Tag was found in this session.  The tag was $allowed_tag.\"}"
    exit 0
fi

printf '{"result":"success"}\n'
    exit 0
