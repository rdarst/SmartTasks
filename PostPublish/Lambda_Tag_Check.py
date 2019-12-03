import json
import os
import boto3

sns = boto3.client('sns')

#SMS Phone Number
#phone_number=os.environ.get('SMS_NUMBER')

def find_tags(string, action, customdata):
    message = ""
    array_length = len(string)
    for i in range(array_length):
      if action == "Modified":
         output = string[i]['new-object']['tags']
         object_name = string[i]['new-object']['name']
         object_type = string[i]['new-object']['type']
      else:
         output = string[i]['tags']
         object_name = string[i]['name']
         object_type = string[i]['type']
      output_length = len(output)
      for q in range(output_length):
        tagoutput = output[q]['name']
        if tagoutput == customdata:
          message = message + "Object(type {}) {} with Tag {} was {}.\n".format(object_type, object_name, tagoutput, action)
    return message

def lambda_handler(event, context):
    #print('## ENVIRONMENT VARIABLES')
    #print(os.environ)
    #print('## EVENT')
    #print(event)
    data = event
    
    customdata = data['custom-data']['allowed-tag']
    phone_number=data['custom-data']['phone_number']
    #print('##customdata ', customdata)
    modified = data['operations']['modified-objects']
    deleted = data['operations']['deleted-objects']
    added = data['operations']['added-objects']

    finalmessage = find_tags(added, "Added", customdata)
    finalmessage = finalmessage + find_tags(deleted, "Deleted", customdata)
    finalmessage = finalmessage + find_tags(modified, "Modified", customdata)

    if finalmessage:
      print("## Final Message")
      print(finalmessage)
      sns.publish(PhoneNumber=phone_number, Message=finalmessage) #Send SMS Message

    return {
        'statusCode': 200,
        'body': ''
      }
