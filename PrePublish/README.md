SmartTask script for PrePublish to check to see the correct object type and tag are supplied before the publish is applied.

**Example JSON for the Custom Data in the SmartTask**
```
{
  "admins":["Mickey"], 
  "allowed-tag":"Web_Control"
}
```
**Run the following command on the management server to configure this SmartTask**

```
curl_cli -kLs https://raw.githubusercontent.com/jimoq/SmartTasks/master/PrePublish/Setup_SmartTask.sh > Setup_SmartTask.sh; bash Setup_SmartTask.sh
```
