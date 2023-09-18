#!/bin/bash

# Update with Installomator if app exist

# This will create a log into '/Library/Intune/installometer_app_install.log'
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>> /Library/Intune/installometer_app_install.log 2>&1

LOGO="microsoft" # "mosyleb", "mosylem", "addigy", "microsoft", "ws1", "kandji"

item="firefoxpkg" # enter the software to install
# Examples: cyberduck, handbrake, textmate, vlc

appPath="/Applications/Firefox.app"
# Examples: Cyberduck.app, Handbrake.app, Textmate.app, VLC.app

installomatorOptions="DEBUG=0 BLOCKING_PROCESS_ACTION=prompt_user NOTIFY=success" # Separated by space

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

echo "$(date +%F\ %T) [LOG-BEGIN] $item"

# Check if app is installed
# We only want this to run if it's already installed
if [ ! -e "${appPath}" ]; then
    echo "App not found here:"
    echo "${appPath}"
    echo "Exiting."
    exit 98
fi
echo "${appPath} Found!"

# Check if the /Library/Intune/Installomator/ folder exists, if not, create it.
if ! [ -d "/Library/Intune/Installomator/" ]
    then
        mkdir -p /Library/Intune/Installomator
    else
        cat /dev/null
fi


# Check if the /Library/Intune/Installomator/installomator_update_list file exists, if not, create it.
if ! [ -f "/Library/Intune/Installomator/installomator_update_list" ]
    then
        touch /Library/Intune/Installomator/installomator_update_list
    else
        cat /dev/null
fi


# This will always download the newest copy of Installomator
curl -o /tmp/Installomator.sh https://raw.githubusercontent.com/Installomator/Installomator/release/Installomator.sh;
chmod +x /tmp/Installomator.sh

destFile="/tmp/Installomator.sh"


#Check if dialog is installed, if not, remove the pkg entry if it exists to allow for clean reinstall from Installomator
if ! [ -x "/Library/Application Support/Dialog/Dialog.app" ]
    then 
        pkgutil --forget au.csiro.dialogcli
        /tmp/Installomator.sh dialog DEBUG=0 BLOCKING_PROCESS_ACTION=kill
    else 
        cat /dev/null
fi

# No sleeping
/usr/bin/caffeinate -d -i -m -u &
caffeinatepid=$!
caffexit () {
    kill "$caffeinatepid"
    exit $1
}


# Install software using Installomator
cmdOutput="$(${destFile} ${item} LOGO=$LOGO ${installomatorOptions} || true)"

# Check result
exitStatus="$( echo "${cmdOutput}" | grep --binary-files=text -i "exit" | tail -1 | sed -E 's/.*exit code ([0-9]).*/\1/g' || true )"
if [[ ${exitStatus} -eq 0 ]] ; then
    echo "${item} succesfully installed."
    selectedOutput="$( echo "${cmdOutput}" | grep --binary-files=text -E ": (REQ|ERROR|WARN)" || true )"
    echo "$selectedOutput"
else
    echo "ERROR installing ${item}. Exit code ${exitStatus}"
    echo "$cmdOutput"
    #errorOutput="$( echo "${cmdOutput}" | grep --binary-files=text -i "error" || true )"
    #echo "$errorOutput"
fi

# Check if the software entry is in the update list, if not, add it.
updatelist=/Library/Intune/Installomator/installomator_update_list

if ! grep -q ${item} "$updatelist";
    then
        echo "${item}" >> $updatelist
    else
        cat /dev/null
fi

echo "[$(DATE)][LOG-END]"

caffexit $exitStatus
