#!/bin/bash

# jumpcloud-install.sh
# v1.0 20160630
# Written by Douglas Nerad.

# Installs the JumpCloud client on a Mac, adds the user to the system, adds tags, names
#	the machine in the JC console.
# Some code ganked from JumpCloud: https://github.com/TheJumpCloud
# More code ganked from The Internet.

# Insure script is run as admin user
if [[ $EUID -ne 0 ]]; then
	echo "You must run this script as root. Try again with \"sudo\""
	echo ""
	exit 0
fi

# ----------------------------------------------------------------------------------------
# ----- Default Variables and Settings ---------------------------------------------------
# Input JC Connect and API keys.
# - Determine user to be added to computer via JC.
# - Determine TAG number.
# ----------------------------------------------------------------------------------------

# Get the CONNECT_KEY from JC Admin Console > Systems > + > Mac Install
CONNECT_KEY="XXXX"
# Get the API_ KEY from JC Admin Console > [your username] > API Settings
API_KEY="XXXX"

# User names to add to the machine via JC.
# USER_SHORTNAME=$( id -un );
# User fullname to use in computer name in JC console.
# USER_FULLNAME=$( id -F );
USER_SHORTNAME="jdoe"
USER_FULLNAME="Jane Doe"
EMAIL_DOMAIN="@example.com"

# In our environment we identify Systems in JumpCloud with an system-type identifier, an asset
#	tag number and the current user's full name. For example: COMP: 123 Douglas Nerad
SYSTEM_TYPE="COMP"
TAG_ID="006"

# JC Tags to add the machine into. If more than one you'll have to hack the code to
#	include those extras.
JC_TAG="comp-osx"


# ----------------------------------------------------------------------------------------
# ----- User in JumpCloud Check ----------------------------------------------------------
# Create the user, if new, in JC
# Extract the JC user ID from JC
# ----------------------------------------------------------------------------------------

USER_FOUND=$( curl --silent -d "{\"filter\": [{\"username\" : \"${USER_SHORTNAME}\"}]}" -H 'Content-Type: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/search/systemusers" --stderr - | sed 's/{.*totalCount":"*\([0-9a-zA-Z]*\)"*,*.*}/\1/' );
if [[ ${USER_FOUND} == 1 ]]; then
	echo "${USER_FULLNAME} already exists in JumpCloud."
else
	echo "We will now add ${USER_FULLNAME} to JumpCloud."
	curl -d "{\"email\" : \"${USER_SHORTNAME}${EMAIL_DOMAIN}\", \"username\" : \"${USER_SHORTNAME}\" }" -X 'POST' -H 'Content-Type: application/json' -H 'Accept: application/json' -H "x-api-key: [YOUR_API_KEY_HERE]" "https://console.jumpcloud.com/api/systemusers"
	echo "${USER_FULLNAME} will have an email requesting they set up their password."
fi
echo ""
sleep 3

USER_KEY=$( curl -v --silent -d "{\"filter\": [{\"username\" : \"${USER_SHORTNAME}\"}]}" -H 'Content-Type: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/search/systemusers" --stderr - | awk -F":" -v RS="," '$1~/"_id"/ {print $2}' | sed 's/^"//' | sed 's/".*//'  | awk -F"\n" -v RS="" '{print $NF}' );


# ----------------------------------------------------------------------------------------
# ----- System in JumpCloud --------------------------------------------------------------
# Pulls latest version if the client and installs it
# Extract the system key for the installation
# ----------------------------------------------------------------------------------------

# Install the JumpCloud client if it isn't installed already
if [ ! -f /opt/jc/jcagent.conf ]; then
	echo "JumpCloud client installation..."
	OLDPWD="$( pwd )"
	sudo mkdir -p /opt/jc
	echo "...Made /opt/jc directory."
	sudo chmod -R 755 /opt
	sudo chown root:wheel /opt
	sudo chown root:admin /opt/jc
	echo "...Fixed permissions for /opt/jc."
	sudo cat > /opt/jc/agentBootstrap.json <<JCBOOTSTRAP
	{
		"publicKickstartUrl": "https://kickstart.jumpcloud.com:443",
		"privateKickstartUrl": "https://private-kickstart.jumpcloud.com:443",
		"connectKey": "${CONNECT_KEY}"
	}
JCBOOTSTRAP
	sudo chown root:admin /opt/jc/agentBootstrap.json
	sudo chmod 644 /opt/jc/agentBootstrap.json
	echo "...Made the agentBootstrap.json file and fixed its permissions."
	sleep 1
	cd /tmp
	sudo curl -O "https://s3.amazonaws.com/jumpcloud-windows-agent/production/jumpcloud-agent.pkg"
	echo "...Downloaded the jumpcloud-agent.pkg installer."
	sudo installer -allowUntrusted -pkg jumpcloud-agent.pkg -target "${TARGET}" 2> /dev/null
	JC_TRY=0
	until [ -f /opt/jc/jcagent.conf ]; do
		sleep 5
		JC_TRY=$((JC_TRY+5))
		echo "......Waited ${JC_TRY} seconds for JumpCloud to install."
	done
	echo "...Installed the JumpCloud client."
	sudo rm jumpcloud-agent.pkg
	sleep 1
	cd "${OLDPWD}"
fi

SYSTEM_KEY=$( sudo cat /opt/jc/jcagent.conf | awk -F":" -v RS="," '$1~/"systemKey"/ {print $2}' | sed 's/^"//' | sed 's/".*//' );


# ----------------------------------------------------------------------------------------
# ----- Configure Computer with JumpCloud ------------------------------------------------
# - Set the system name in JC
# - Add the system to comp-osx Tag
# - Add the user to the system
# - Make the user admin (sudo) on their own computer
# ----------------------------------------------------------------------------------------

# Set the system name in JC
curl -iq -d "{ \"displayName\" : \"COMP: ${TAG_ID} ${USER_FULLNAME}\"}" -X 'PUT' -H 'Content-Type: application/json' -H 'Accept: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/systems/${SYSTEM_KEY}"
echo "In the JumpCloud console the computer is called ${SYSTEM_TYPE}: ${TAG_ID} ${USER_FULLNAME}."
sleep 3

# Add the system to the OSX tag
if [ -n ${TAG_ID} ]; then
curl -iq -d "{ \"tags\" : [\"${JC_TAG}\"]}" -X 'PUT' -H 'Content-Type: application/json' -H 'Accept: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/systems/${SYSTEM_KEY}"
echo "In the JumpCloud console the computer can be found in the ${JC_TAG} tag."
sleep 3
fi

# Allow user to access the machine
curl -d "{ \"add\" : [\"${SYSTEM_KEY}\"], \"remove\" : [] }" -X 'PUT' -H 'Content-Type: application/json' -H 'Accept: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/systemusers/${USER_KEY}/systems"
echo "The JumpCloud user, ${USER_FULLNAME}, can log into this computer."
sleep 3

# Make the user admin (sudo user) on the machine
curl -d "{ \"${SYSTEM_KEY}\": { \"_id\": \"sudoerID\", \"sudoEnabled\": true, \"sudoWithoutPassword\": false }}" -X 'PUT' -H 'Content-Type: application/json' -H 'Accept: application/json' -H "x-api-key: ${API_KEY}" "https://console.jumpcloud.com/api/systemusers/${USER_KEY}/systems/sudoers"
echo "The JumpCloud user, ${USER_FULLNAME}, is now an admin user on this computer."
sleep 3
