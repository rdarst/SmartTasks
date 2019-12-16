SmartTask script for PrePublish to check to see the correct object type and tag are supplied before the publish is applied.

**Example JSON for the Custom Data in the SmartTask**
```
{
  "admins":["Mickey"], 
  "allowed-tag":"Web_Control"
}
```
**Setup Script for PrePublish**

```
echo '#!/bin/bash' > add-smart-task_pre_publish_check.sh
echo 'read -p "Enter the admin you want to check: " allowed_admin' >> add-smart-task_pre_publish_check.sh
echo 'read -p "Enter the tag name you tagged your objects with: " allowed_tag' >> add-smart-task_pre_publish_check.sh
echo '# Adding the pre-publish-tag-check.sh to the script repository on the management server' >> add-smart-task_pre_publish_check.sh
echo 'mgmt_cli -r true add-generic-object create com.checkpoint.management.cdm.objects.scripts.Script name "Pre Publish Check Script" body "'$(base64 pre-publish-tag-check.sh -w 0)'" comments "This script validates that the admin is allowed to make changes to objects with the required tags." -f json | jq .uid' >> add-smart-task_pre_publish_check.sh
echo '# Adding the smart-task Policy Sanity Check to the management server' >> add-smart-task_pre_publish_check.sh
echo "mgmt_cli -r true -f json add smart-task name \"Pre Publish Tag Check\" color \"violet red\" description \"Run a sanity check script to check if the administrator made a policy changes to objects with the required tags.  If the admin made changes outside of the required tags the publish will fail.\" enabled true trigger \"Before Publish\" custom-data '{\n\"admins\": [\"'\${allowed_admin}'\"], \n\"allowed-tag\": \"'\${allowed_tag}'\" \n}' action.run-script.repository-script \"Pre Publish Check Script\"" >> add-smart-task_pre_publish_check.sh
bash add-smart-task_pre_publish_check.sh
```
