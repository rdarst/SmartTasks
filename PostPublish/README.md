SmartTask script for PostPublish calls a lambda function to check if a tag on the object has been created, updated or modified.  A notification is 
made to the phone number by text message if it has.

**Example JSON for the Custom Data in the SmartTask**
```
{
  "phone_number":"740-555-1212", 
  "allowed-tag":"Web_Control"
}
```
**Use this command to add the SmartTask.**
```
mgmt_cli -r true -f json add smart-task name "Post Publish Application Tag Check" color "orange" action.send-web-request.url "https://mxz9711ac6.execute-api.us-east-1.amazonaws.com/default/SmartTask_Notify" action.send-web-request.time-out 60 description "Check to see if a object has been updated with a specific Tag as defined in the custom data" enabled true trigger "After Publish" custom-data '{\n "phone_number" : "1-740-555-1212", \n "allowed-tag" : "Web_Control"\n}'
```
