SmartTask script for PostInstall to sanity check the installed policy, if the check fail revert to last good known policy and open a ticket in service now to the administrator who initiated the policy install.

**Example JSON for the Custom Data in the SmartTask**
```
{
  "smarttask_servicenow_user": "my_automation_user_for_service_now",
  "smarttask_servicenow_password": "my_automation_user_password",
  "short_description": "Check Point SmartTask has reverted to last good known policy since critical traffic was blocked due to your policy installation on gateway(s):", 
  "comments": "policy has been automatically reverted to last good known policy by Check Point SmartTasks. This has been done due to failed sanity check of critical business applications traffic. Verify and adjust your policy changes accordingly and install your updated policy."
}
```
