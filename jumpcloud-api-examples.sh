#!/bin/bash

# jumpcloud-api-examples.sh
# v.20210105
# Douglas Nerad

# These are JumpCloud API examples, using both version 1 and 2 APIs. I've labelled the
# API used in each case.

# -------------------------------------------------------------------------------------- #
# A couple defaults to get you started. These could be made to be more dynamic.

API_KEY="YourKeyHere"
USER="harrypotter"
USER_REALNAME="Harry Potter"
USER_GROUP="gryffindor"
ASSET_TAG="19800731"
SYSTEM_GROUP="horcruxes"

# -------------------------------------------------------------------------------------- #
# User manipulation

# v1 Get user_id string.
USER_ID=$( curl -v --silent -d "{\"filter\": [{\"username\" : \"${USER}\"}]}" -H 'Content-Type: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/search/systemusers" --stderr - | awk -F":" -v RS="," '$1~/"_id"/ {print $2}' | sed 's/^"//' | sed 's/".*//'  | awk -F"\n" -v RS="" '{print $NF}' )

# v2 gets the user groups a user is associated with.
curl -X 'GET' -H 'Content-Type: application/json' -H 'Accept: application/json'  -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/v2/users/${USER_ID}/memberof"

# v2 allows a user to access a specific system (requires system_id)
curl -d "{ \"op\":\"add\", \"type\":\"system\", \"id\":\"${SYSTEM_ID}\" }" -X 'POST' -H 'Content-Type: application/json' -H 'Accept: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/v2/users/${USER_ID}/associations"

# v2 allows a user to access a specific system as admin (requires system_id)
curl -d "{ \"op\": \"add\", \"type\": \"system\", \"id\": \"${SYSTEM_ID}\", \"attributes\": {\"sudo\": {\"enabled\": true, \"withoutPassword\": false} } }" -X 'POST' -H 'Content-Type: application/json' -H 'Accept: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/v2/users/${USER_KEY}/associations"

# v2 gets the systems related to a particular user.
curl -X 'GET' -H 'Content-Type: application/json' -H 'Accept: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/v2/users/${USER_ID}/systems"

# -------------------------------------------------------------------------------------- #
# User group manipulation

# v2 gets the user_group_id string
USER_GROUP_ID=$( curl -X 'GET' -H 'Content-Type: application/json' -H 'Accept: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/v2/usergroups?limit=100&filter=name:eq:${USER_GROUP}" --stderr - | awk -F":" -v RS="," '$1~/"id"/ {print $2}' | sed 's/^"//' | sed 's/".*//' | awk -F"\n" -v RS="" '{print $NF}' )

# v2 adds a user to a user_group
curl -d "{ \"op\":\"add\", \"type\":\"user\", \"id\":\"${USER_ID}\" }" -X 'POST' -H 'Content-Type: application/json' -H 'Accept: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/v2/usergroups/${USER_GROUP_ID}/members"

# -------------------------------------------------------------------------------------- #
# System manipulation

# cat command to get the system_id
cat /opt/jc/jcagent.conf | awk -F":" -v RS="," '$1~/"systemKey"/ {print $2}' | sed 's/^"//' | sed 's/".*//'

# v1 gets the system_id if you can't use the local cat command
SYSTEM_ID=$( curl -v --silent -d "{\"filter\": [{\"displayName\" : { \"\$regex\" : \"${ASSET_TAG}\"}}]}" -H 'Content-Type: application/json' -H 'Accept: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/search/systems" --stderr - | awk -F":" -v RS="," '$1~/"_id"/ {print $2}' | sed 's/^"//' | sed 's/".*//'  | awk -F"\n" -v RS="" '{print $NF}' )

# v1 sets the name of the system in the JC console
curl -iq -d "{ \"displayName\" : \"COMP: ${TAG_ID} ${USER_REALNAME}\"}" -X 'PUT' -H 'Content-Type: application/json' -H 'Accept: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/systems/${SYSTEM_KEY}"

# v2 gets the groups the system is in
curl -X 'GET' -H 'Content-Type: application/json' -H 'Accept: application/json'  -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/v2/systems/${SYSTEM_KEY}/memberof"

# -------------------------------------------------------------------------------------- #
# System group manipulation

# v2 gets the system_group_id string for comp-osx
SYSTEM_GROUP_ID=$( curl -X 'GET' -H 'Content-Type: application/json' -H 'Accept: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/v2/systemgroups?limit=100&filter=name:eq:${SYSTEM_GROUP}" --stderr - | awk -F":" -v RS="," '$1~/"id"/ {print $2}' | sed 's/^"//' | sed 's/".*//' | awk -F"\n" -v RS="" '{print $NF}' )

# v2 add system to system_group: 
curl -d "{ \"op\":\"add\", \"type\":\"system\", \"id\":\"${SYSTEM_ID}\" }" -X 'POST' -H 'Content-Type: application/json' -H 'Accept: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/v2/systemgroups/${SYSTEM_GROUP_ID}/members"
