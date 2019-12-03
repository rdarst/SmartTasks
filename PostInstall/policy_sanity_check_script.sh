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

# This function will revert the policy to a previous revision
function revert_to_last_good_known_policy()
{
  mgmt_cli -r true --format json install-policy \
  policy-package "$install_policy_package" access true targets.1 "$install_policy_targets" \
  revision "18d4f80f-fd8e-4ac4-b690-5597b0cb5397" > /tmp/revert.json
}

# This funtion will create a servicenow incident ticket using the servicenow API
function servicenow_report_incident()
{
  curl_cli "https://dev71699.service-now.com/api/now/table/incident" \
  --insecure \
  --request POST \
  --header "Accept:application/json" \
  --header "Content-Type:application/json" \
  --data '{"short_description":"'"$short_description $install_policy_targets"'", "comments":"'"$install_policy_package $comments"'", "active": "true", "caller_id": "'"$install_policy_initiator"'", "urgency": "1", "impact": "1", "priority": "1"}' \
  --user "$smarttask_servicenow_user":"$smarttask_servicenow_password"
} 

# This function will verify that the CPX360 business critical traffic is working after policy install
function sanity_check()
{
  curl_cli "https://postman-echo.com/response-headers?Event=CPX360_is_kicking" \
  --silent \
  --insecure \
  --location \
  --request GET  \
  | jq '.Event | contains("CPX360_is_kicking")'
}

# If the install policy fails, exit without error
if [[ $(echo $install_policy_result | jq 'contains("Succes")') = "false" ]]; then
  exit 0
fi

# Checking traffic to critical business application and stores the result
sanity_check_result=$(sanity_check)

# If the install policy succeeds, execute sanity checks
if [[ $(echo $sanity_check_result) != "true" ]]; then
  servicenow_report_incident &
  revert_to_last_good_known_policy
  exit 1
fi