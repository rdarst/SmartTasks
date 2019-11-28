#!/bin/bash
function servicenow_report_incident()
{
  curl_cli "https://dev71699.service-now.com/api/now/table/incident" \
  --insecure \
  --request POST \
  --header "Accept:application/json" \
  --header "Content-Type:application/json" \
  --data "{\"short_description\":\"short descr Test incident creation through Check Point mgmt\",\"comments\":\"these are my rest comments caller sys admin\",\"active\":\"true\",\"caller_id\":\"System Administrator\",\"urgency\":\"1\",\"impact\":\"1\",\"priority\":\"1\"}" \
  --user 'admin':'mypassword'
} 




trigger_json=$(echo $1 | base64 --decode -i)
echo $trigger_json > /tmp/policy_install_trigger.json

# Getting the end result of the install policy
install_policy_result=$(echo $trigger_json | jq .installPolicyResult)

# If the install policy fails, exit without error
if [[ $(echo $install_policy_result | jq 'contains("Succes")') = "false" ]]; then
  exit 0
fi

sanity_check=$(curl_cli --silent --insecure --location --request GET "https://postman-echo.com/response-headers?Event=CPX360_is_kicking" | jq '.Event | contains("CPX360_is_kicking")')

# If the install policy succeeds, execute sanity checks
if [[ $(echo $sanity_check) != "true" ]]; then
  mgmt_cli -r true install-policy policy-package "standard" access true targets.1 "smsg60" revision "18d4f80f-fd8e-4ac4-b690-5597b0cb5397" --format json > /tmp/revert.json
  sanity_notification=$(echo $trigger_json | jq  '{"Policy": .tasksResult[].target,"installed by": .initiator,"message": "failed sainty check of critical services, reverting to last good known policy, request to validate the policy have been sent to the intiator of the policy install"}'
  echo $sanity_notification > /tmp/policy_sanity_notification.out
  exit 1
fi


