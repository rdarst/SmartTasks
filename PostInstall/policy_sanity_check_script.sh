#!/bin/bash

# base64 decoding and storing the SmartTask JSON response
trigger_json=$(echo $1 | base64 --decode -i)
#echo $trigger_json > /tmp/policy_install_trigger.json

# Getting initiator of policy install
install_policy_initiator=$(echo $trigger_json | jq -r .initiator)
# Getting the end result of the policy install
install_policy_result=$(echo $trigger_json | jq .installPolicyResult)
# Getting the policy package name from the policy install
install_policy_package=$(echo $trigger_json | jq -r .policyPackage)
# Getting the targets for the policy install
install_policy_targets=$(echo $trigger_json | jq -r .tasksResult[].target)
# Getting the ServiceNow user to be used by SmartTask to create an incident in ServiceNow
smarttask_servicenow_user=$(echo $trigger_json | jq -r '."custom-data".smarttask_servicenow_user')
# Getting the ServiceNow password to be used by SmartTask to create an incident in ServiceNow
smarttask_servicenow_password=$(echo $trigger_json | jq -r '."custom-data".smarttask_servicenow_password')
# Getting the ServiceNow Host to be used by SmartTask to create an incident in ServiceNow
smarttask_servicenow_host=$(echo $trigger_json | jq -r '."custom-data".smarttask_servicenow_host')
# Getting the short description to be used in the incident created in ServiceNow
short_description=$(echo $trigger_json | jq -r '."custom-data".short_description')
# Getting the short description to be used in the incident created in ServiceNow
comments=$(echo $trigger_json | jq -r '."custom-data".comments')

# Get the number of targets and build a string from the json
num_of_targets=`echo "$install_policy_targets" |wc -l`
i=1
targets=""
install_targets=""
while read -r line
do
   targets+="$line"
   install_targets+="targets.$i $line "
   if [ $i -lt $num_of_targets ]
   then
     targets+=","
     i=$((i+1))
   fi
done  <<<"$install_policy_targets"


# This function will revert the policy to a previous revision
function revert_to_last_good_known_policy()
{
  mgmt_cli -r true --format json install-policy \
  policy-package "$install_policy_package" access true \
  revision "d43eff97-0c56-48f6-9bb4-8ae002f166d3" > /tmp/revert.json
}

# This function will create a servicenow incident ticket using the servicenow API
function servicenow_report_incident()
{
    json_post_data="{\"short_description\":\"${short_description} ${targets}\", \"comments\":\"${install_policy_package} ${comments}\", \"active\": \"true\", \"caller_id\": \"$install_policy_initiator\", \"urgency\": \"1\", \"impact\": \"1\", \"priority\": \"1\"}"
  echo "$json_post_data" > /tmp/api_out.txt
  curl_cli "https://${smarttask_servicenow_host}/api/now/table/incident" \
  --insecure \
  --request POST \
  --header "Accept:application/json" \
  --header "Content-Type:application/json" \
  --data "$json_post_data" \
  --user "$smarttask_servicenow_user":"$smarttask_servicenow_password"
}

# This function will verify that the CPX360 business critical traffic is working after policy install
function sanity_check()
{
  curl_cli 'https://postman-echo.com/response-headers?Event=CPX360_is_kicking!' \
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
  sleep 5
  revert_to_last_good_known_policy
  exit 1
fi
