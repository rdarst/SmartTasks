#!/bin/bash

trigger_json=`echo $1 | base64 --decode -i`
echo $trigger_json > /tmp/trigger.json
# Getting the list of relevant admins from the custom data
relevant_admins=`echo $trigger_json | jq .\"custom-data\".admins`
echo $relevant_admins >> /tmp/trigger.json
# Name of the admin that's publishing a session
publishing_admin=`echo $trigger_json | jq -r .session.\"user-name\"`
echo $publishing_admin >> /tmp/trigger.json
# If the publishing admin isn't relevant for validation, exit without error
if [[ `echo $relevant_admins | jq --arg ADMIN "$publishing_admin" 'contains([$ADMIN])'` = "false" ]]; then
  printf '{"result":"success"}\n'
  exit 0
fi 
# Getting the allowed tag
allowed_tag=`echo $trigger_json | jq -r .\"custom-data\".\"allowed-tag\"`

# check type of objects that were create/modified/deleted in this session
session_objcets=`echo $trigger_json | jq '.operations | (."added-objects"[] | {"name":.name , "type":.type}) , (."deleted-objects"[] | {"name":.name, "type":.type}), (."modified-objects"[] | {"name":."new-object".name, "type":."new-object".type})' | jq -s .`
session_objects_details=`echo $session_objcets | jq '.[] | {"name":.name, "type":.type, "valid_type": ( [.type]-["host","network","group","access-rule","application-site-group"]| length == 0)}' | jq -s .`
number_of_objects_with_bad_type=`echo $session_objects_details | jq '.[] | select(."valid_type" == false)' | jq -s '. | length'`
list_of_objects_with_bad_type=`echo $session_objects_details | jq '.[] | select(."valid_type" == false)' | jq -s -c '[.[] | .name]' | tr -d [ | tr -d ] | tr -d '"'`
if [ $number_of_objects_with_bad_type -gt 0 ]; then
    echo "{\"result\":\"failure\", \"message\":\"You can only create/modifiy/delete of type: host, network, group, access rule, application/site group.\n The following objects cannot be created/modified/deleted (unauthorized object type): $list_of_objects_with_bad_type\"}"
	exit 0
fi

# check objects that were created as part of the session
# look for mandatory tag
created_objects=`echo $trigger_json | jq '.operations | ."added-objects"[] | {"Name":.name, "Type":.type, "With_Tag":([.tags[].name] | index($TAG_NAME)!=null), "Tag_count":(.tags | length)}' --arg TAG_NAME "$allowed_tag" | jq -s .`
number_of_created_objects_without_tag=`echo $created_objects | jq ' .[] | select(."With_Tag" == false) ' | jq -s '. | length'`
list_of_created_objects_without_tag=`echo $created_objects | jq ' .[] | select(."With_Tag" == false) ' | jq -s -c '[.[] | .Name]' | tr -d [ | tr -d ] | tr -d '"'`
if [ $number_of_created_objects_without_tag -gt 0 ]; then
	echo "{\"result\":\"failure\", \"message\":\"You can only modify objects with the tag $allowed_tag. The following objects don't have this tag: $list_of_created_objects_without_tag \"}"
    exit 0
fi

# see if there's no extra tag
number_of_objects_with_more_than_one_tag=`echo $created_objects | jq ' .[] | select( (."With_Tag" == true) and (."Tag_count" != 1) ) ' | jq -s '. | length'`
list_of_objects_with_more_than_one_tag=`echo $created_objects | jq ' .[] | select( (."With_Tag" == true) and (."Tag_count" != 1) ) ' | jq -s -c '[.[] | .Name]' | tr -d [ | tr -d ] | tr -d '"'`
if [ $number_of_objects_with_more_than_one_tag -gt 0 ]; then
	echo "{\"result\":\"failure\", \"message\":\"You can only create objects with a single tag, $allowed_tag. The following objects have an extra tag in addition to this tag: $list_of_objects_with_more_than_one_tag.\"}"
    exit 0
fi

# check objects that were deleted as part of the session
deleted_objects=`echo $trigger_json | jq '.operations | ."deleted-objects"[] | {"Name":.name,"Type":.type,"With_Tag":([.tags[].name] | index($TAG_NAME)!=null),"Tag_count":(.tags | length)}' --arg TAG_NAME "$allowed_tag" | jq -s .`
number_of_deleted_objects_without_tag=`echo $deleted_objects | jq ' .[] | select(."With_Tag" == false)' | jq -s ' . | length'`
list_of_deleted_objects_without_tag=`echo $deleted_objects | jq ' .[] | select(."With_Tag" == false) ' | jq -s -c '[.[] | .Name]' | tr -d [ | tr -d ] |tr -d '"'`
if [ $number_of_deleted_objects_without_tag -gt 0 ]; then
	echo "{\"result\":\"failure\", \"message\":\"You can only delete objects with the tag $allowed_tag.  The following objects don't have this tag: $list_of_deleted_objects_without_tag \"}"
    exit 0
fi

# check objects that were modified as part of the session
modified_objects=`echo $trigger_json | jq '.operations | ."modified-objects"[] | {"Name":."new-object".name, "Type":."old-object".type, "With_Tag": ([."old-object".tags[].name] | index($TAG_NAME)!=null),"Tag_count":(."old-object".tags | length)}' --arg TAG_NAME "$allowed_tag" | jq -s .`
number_of_modified_objects_without_tag=`echo $modified_objects | jq ' .[] | select(."With_Tag" == false)' | jq -s '. | length'`
list_of_modified_objects_without_tag=`echo $modified_objects | jq ' .[] | select(."With_Tag" == false) ' | jq -s -c '[.[] | .Name]' | tr -d [ | tr -d ] | tr -d '"'`
if [ $number_of_modified_objects_without_tag -gt 0 ]; then
	echo "{\"result\":\"failure\", \"message\":\"You can only modify objects with the tag $allowed_tag. The following objects don't have this tag: $list_of_modified_objects_without_tag \"}"
    exit 0
fi

# check that the object's tag list is the same for modified objects.
modified_objects_with_all_tags=`echo $trigger_json | jq '.operations | ."modified-objects"[] | {"name":."new-object".name, "old-tags":[."old-object".tags[].name], "new-tags":[."new-object".tags[].name] }' | jq -s .`
modified_objects_with_tags_diff=`echo $modified_objects_with_all_tags | jq '.[] | {"name": .name , "removed": (."old-tags" - ."new-tags" | length), "added":(."new-tags" - ."old-tags" | length)}' | jq -s .`
modified_objects_with_changed_tags=`echo $modified_objects_with_tags_diff | jq '.[] | {"name" : .name, "changed":((.added+.removed) != 0)}' | jq -s .`
number_of_objects_with_changed_tags=`echo $modified_objects_with_changed_tags | jq ' .[] | select(.changed == true)' | jq -s '. |length'`
list_of_objects_with_changed_tags=`echo $modified_objects_with_changed_tags | jq ' .[] | select(.changed == true)' | jq -s -c '[.[] | .name]' | tr -d [ | tr -d ] | tr -d '"' `
if [ $number_of_objects_with_changed_tags -gt 0 ]; then
    echo "{\"result\":\"failure\", \"message\":\"The following objects cannot be modified (you are not allowed to change their tags): $list_of_objects_with_changed_tags\"}"
	exit 0
fi
printf '{"result":"success"}\n'
    exit 0
