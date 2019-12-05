SmartTask script for PostPublish calls a lambda function to check if a tag on the object has been created, updated or modified.  A notification is 
made to the phone number by text message if it has.

**Example JSON for the Custom Data in the SmartTask**
```
{
  "phone_number":"740-555-1212", 
  "allowed-tag":"Web_Control"
}
```
**Use this command to add the SmartTask using the existing Lambda computing service.**
```
mgmt_cli -r true -f json add smart-task name "Post Publish Application Tag Check" color "orange" action.send-web-request.url "https://mxz9711ac6.execute-api.us-east-1.amazonaws.com/default/SmartTask_Notify" action.send-web-request.time-out 60 description "Check to see if a object has been updated with a specific Tag as defined in the custom data" enabled true trigger "After Publish" custom-data '{\n "phone_number" : "1-740-555-1212", \n "allowed-tag" : "Web_Control"\n}'
```

**Use these commands to add the SmartTask using your customized Lambda computing service.**
1. Download the Lambda_Tag_Check.py and put it on your Lambda computing service.
2. Run the following commands on your management server to add the SmartTask, it will ask you to:
-Specify the URL to the URL of your Lambda service (needs to be valid HTTPS URL)
-Specify the  phone number you want to send the SMS to
-Specify the name of the tag you want to use in the your Check Point management server.

```
echo '#!/bin/bash' > add-smart-task_post_publish_application_tag_check.sh
echo 'read -p "Enter the URL of your Lambda computing service where you placed the Lambda_Tag_Check.py code: " lambda_url' >> add-smart-task_post_publish_application_tag_check.sh
echo 'read -p "Enter the phone number to send the SMS notification to: " phone_number' >> add-smart-task_post_publish_application_tag_check.sh
echo 'read -p "Enter the tag name you tagged your objects with: " allowed_tag' >> add-smart-task_post_publish_application_tag_check.sh
echo 'mgmt_cli -r true -f json add smart-task name "Post Publish Application Tag Check" color "orange" action.send-web-request.url "$lambda_url" action.send-web-request.time-out 60 description "Check to see if a object has been updated with a specific Tag as defined in the custom data" enabled true trigger "After Publish" custom-data '{\n "phone_number" : "$phone_number", \n "allowed-tag" : "$allowed_tag"\n}' >> add-smart-task_post_publish_application_tag_check.sh
bash add-smart-task_post_publish_application_tag_check.sh
```