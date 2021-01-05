# JumpCloud Installer
I made this script to help with the installation of the JumpCloud (JC) client on macOSX and to make API calls to the JumpCloud console to push and pull data.

NOTE: This utilizes the old JumpCloud API version 1.0. There is a new API; I will be creating a new project to utilize v2.0.

BONUS: I've added a script with a bunch of various CLI API calls.

# Specifically...
## jumplcloud-install.sh follows this workflow:

1: It determines if the user is already in JC.
- If not it creates the user in the JC console.

2: It extracts the user key from the JC console.

3: It installs the JC client if it isn't already present.

4: It extracts the system key from the JC console.

5: It makes some API calls to the JC console.
- Sets the name of the system in the JC console.
- Adds the system to a specific tag in the JC console.
- Adds the user to the system.
- Elevates the user to "sudo" level for the system.

## Variables

- Get the CONNECT KEY from JC Admin Console > Systems > + > Mac Install
- Get the API KEY from JC Admin Console > [your username] > API Settings
- Username information, including JC username, Full Name, and the "@example.com" used in their email address.
- System type and asset tag number.
- JC Tag to add the system into by default.

## Usage

Put this script somewhere useful, like a USB stick. Make it executable. Then `cd` to its location and run it.

`./jumpcloud-install.sh`

## Why This Script

I have another project that I wanted to add configuration for JumpCloud API calls. This script was my test bed. JumpCloud's API is pretty powerful but I found bits of it tricky and thought this script might serve others. Really, the only macOSX specific portions is the link to the installer package; this could be changed to serve whatever system you need.
