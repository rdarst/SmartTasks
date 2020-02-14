#!/bin/bash
varSid=$(mgmt_cli -r true -f json login | jq -r '.sid')
curl_cli -kLs https://raw.githubusercontent.com/jimoq/SmartTasks/master/PrePublish/Prepublish.sh > pre-publish-tag-check.sh
read -p "Enter the admin you want to check (e.g.: api_user): " allowed_admin
read -p "Enter the tag name you tagged your objects with (e.g.: Cloud): " allowed_tag
mgmt_cli --session-id $varSid -f json add-tag name "$allowed_tag" color "violet red" | jq .name
# Adding the pre-publish-tag-check.sh to the script repository on the management server
mgmt_cli --session-id $varSid -f json add-generic-object create com.checkpoint.management.cdm.objects.scripts.Script name "Pre Publish Check Script" body "$(base64 pre-publish-tag-check.sh -w 0)" comments "This script validates that the admin is allowed to make changes to objects with the required tags." | jq .name
# Adding the smart-task Policy Sanity Check to the management server
mgmt_cli --session-id $varSid -f json add smart-task name "Pre Publish Tag Check" color "violet red" description "Run a sanity check script to check if the administrator made a policy changes to objects with the required tags.  If the admin made changes outside of the required tags the publish will fail." enabled true trigger "Before Publish" custom-data '{\n"admins": ["'${allowed_admin}'"], \n"allowed-tag": "'${allowed_tag}'" \n}' action.run-script.repository-script "Pre Publish Check Script"
mgmt_cli --session-id $varSid -f json publish
mgmt_cli --session-id $varSid -f json logout
