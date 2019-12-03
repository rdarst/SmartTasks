SmartTask script for PostPublish calls a lambda function to check if a tag on the object has been created, updated or modified.  A notification is 
made to the phone number by text message if it has.

**Example JSON for the Custom Data in the SmartTask**
```
{
  "phone_number":"740-555-1212", 
  "allowed-tag":"Web_Control"
}
```
