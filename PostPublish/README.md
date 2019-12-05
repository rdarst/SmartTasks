SmartTask script for PostPublish calls a lambda function to check if a tag on the object has been created, updated or modified.  A notification is 
made to the phone number by text message if it has.

**Example JSON for the Custom Data in the SmartTask**
```
{
  "phone_number":"740-555-1212", 
  "allowed-tag":"Web_Control"
}
```

**Codified installation of the SmartTask
Download the Lambda_Tag_Check.py and put it on your Lambda computing service.
Run the following commands on your management server to add the SmartTask, it will ask you to:
-Specify the URL to the URL of your Lambda service (needs to be valid HTTPS URL)
-Specify the  phone number you want to send the SMS to
-Specify the name of the tag you want to use in the your Check Point management server.

```
echo '#!/bin/bash' > add-smart-task_object_modification_notified_over_sms.sh
echo 'read -p "Enter the URL of your Lambda computing service where you placed the Lambda_Tag_Check.py code: " lambda_url' >> add-smart-task_object_modification_notified_over_sms.sh
echo 'read -p "Enter the phone number to send the SMS notification to: " phone_number' >> add-smart-task_object_modification_notified_over_sms.sh
echo 'read -p "Enter the tag name you tagged your objects with: " allowed_tag' >> add-smart-task_object_modification_notified_over_sms.sh
echo 'mgmt_cli -r true -f json add smart-task name "Object Modification Notified Over SMS" color "blue" description "Call a Lambda function to check if a object with the custom tag have been created, updated or modified. A notification is made to the phone number by text message if it has" enabled true trigger "After Publish" custom-data "{\n\"phone_number\" : \"$phone_number\",\n\"allowed-tag\" : \"$allowed_tag\"\n}" action.send-web-request.url "$lambda_url"' >> add-smart-task_object_modification_notified_over_sms.sh
bash add-smart-task_object_modification_notified_over_sms.sh
```