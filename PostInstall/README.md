SmartTask script for PostInstall to sanity check the installed policy, if the check fail revert to last good known policy and open a ticket in service now to the administrator who initiated the policy install.

**Example JSON for the Custom Data in the SmartTask**
```
{
  "smarttask_servicenow_user": "my_automation_user_for_service_now",
  "smarttask_servicenow_password": "my_automation_user_password",
  "smarttask_servicenow_host": "dev12345.service-now.com",
  "short_description": "Check Point SmartTask has reverted to last good known policy since critical traffic was blocked due to your policy installation on gateway(s):", 
  "comments": "policy has been automatically reverted to last good known policy by Check Point SmartTasks. This has been done due to failed sanity check of critical business applications traffic. Verify and adjust your policy changes accordingly and install your updated policy."
}
```

Download the policy_sanity_check_script.sh to your management server and run the following commands to add a SmartTask that will use this script.
```
echo '#!/bin/bash' > add-smart-task_policy_sanity_check.sh
echo '# Adding the policy_sanity_check_script.sh to the script repository on the management server' >> add-smart-task_policy_sanity_check.sh
echo 'mgmt_cli -r true add-generic-object create com.checkpoint.management.cdm.objects.scripts.Script name "Policy Sanity Check Script" body "'$(base64 policy_sanity_check_script.sh -w 0)'" comments "This script validates that the installed policy allows business critical applications traffic, if needed revert to last good known policy and open a incident ticket in ServiceNow" -f json | jq .uid' >> add-smart-task_policy_sanity_check.sh
echo '# Adding the smart-task Policy Sanity Check to the management server' >> add-smart-task_policy_sanity_check.sh
echo "mgmt_cli -r true -f json add smart-task name \"Policy Sanity Check\" color \"sea green\" description \"Run a sanity check script to check if the administrator made a policy change that blocks business critical applications traffic, if needed revert to last good known policy and open a incident ticket in ServiceNow\" enabled true trigger \"After Install Policy\" custom-data '{\n\"smarttask_servicenow_user\": \"my_automation_user_for_service_now\", \n\"smarttask_servicenow_password\": \"my_automation_user_password\", \n\n\"short_description\": \"Check Point SmartTask has reverted to last good known policy since critical traffic was blocked due to your policy installation on gateway"\(s\):"\", \n\n\"comments\": \"policy has been automatically reverted to last good known policy by Check Point SmartTasks. This has been done due to failed sanity check of critical business applications traffic. Verify and adjust your policy changes accordingly and install your updated policy.\"\n}' action.run-script.repository-script \"Policy Sanity Check Script\"" >> add-smart-task_policy_sanity_check.sh
bash add-smart-task_policy_sanity_check.sh
```
