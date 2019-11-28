#!/bin/bash

# base64 decoding and storing the SmartTask JSON response
trigger_json=$(echo $1 | base64 --decode -i)
echo $trigger_json > /tmp/policy_install_trigger.json

# Getting initiator of policy install
install_policy_initiator=$(echo $trigger_json | jq -r .initiator)
# Getting the end result of the policy install
install_policy_result=$(echo $trigger_json | jq .installPolicyResult)
# Getting the policy package name from the policy install
install_policy_package=$(echo $trigger_json | jq -r .tasksResult[].target)
# Getting the targets for the policy install
install_policy_targets=$(echo $trigger_json | jq -r .policyPackage)
# Getting the ServiceNow user to be used by SmartTask to creat a incident in ServiceNow
smarttask_servicenow_user=$(echo $trigger_json | jq -r '."custom-data".smarttask_servicenow_user')
# Getting the ServiceNow password to be used by SmartTask to creat a incident in ServiceNow
smarttask_servicenow_password=$(echo $trigger_json | jq -r '."custom-data".smarttask_servicenow_password')
# Getting the short description to be used in the incident created in ServiceNow 
short_description=$(echo $trigger_json | jq -r '."custom-data".short_description')
# Getting the short description to be used in the incident created in ServiceNow 
comments=$(echo $trigger_json | jq -r '."custom-data".comments')

function servicenow_report_incident()
{
  curl_cli "https://dev71699.service-now.com/api/now/table/incident" \
  --insecure \
  --request POST \
  --header "Accept:application/json" \
  --header "Content-Type:application/json" \
  --data '{"short_description":"'"$short_description $install_policy_targets"'","comments":"'"$install_policy_package $comments"'", "active": "true", "caller_id": "System Administrator", "urgency": "1", "impact": "1", "priority": "1"}' \
  --user "$smarttask_servicenow_user":"$smarttask_servicenow_password"
} 

# If the install policy fails, exit without error
if [[ $(echo $install_policy_result | jq 'contains("Succes")') = "false" ]]; then
  exit 0
fi

# Checking traffic to crtical business application and stores the result
sanity_check=$(curl_cli --silent --insecure --location --request GET "https://postman-echo.com/response-headers?Event=CPX360_is_kicking" | jq '.Event | contains("CPX360_is_kicking")')

# If the install policy succeeds, execute sanity checks
if [[ $(echo $sanity_check) != "true" ]]; then
  mgmt_cli -r true install-policy policy-package "standard" access true targets.1 "smsg60" revision "18d4f80f-fd8e-4ac4-b690-5597b0cb5397" --format json > /tmp/revert.json
  #sanity_notification=$(echo $trigger_json | jq  '{"Policy": .tasksResult[].target,"installed by": .initiator,"message": "failed sainty check of critical services, reverting to last good known policy, request to validate the policy have been sent to the intiator of the policy install"}'
  servicenow_report_incident
  #echo $sanity_notification > /tmp/policy_sanity_notification.out
  exit 1
fi