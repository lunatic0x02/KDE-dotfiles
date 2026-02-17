#!/bin/bash

CONFIG="kwinrc"
SECTION="Script-karousel"
KEY="scrollingCentered"
ENABLEKEY="karouselEnabled"

# Toggle Logic
ENABLECURRENT=$(kreadconfig6 --file $CONFIG --group Plugins --key $ENABLEKEY)
current=$(kreadconfig6 --file $CONFIG --group $SECTION --key $KEY)

if [[ "$ENABLECURRENT" == "true" ]]; then
    echo "$current"
    if [ "$current" == "true" ]; then
        new_value="false"
    else
        new_value="true"
    fi

    kwriteconfig6 --file $CONFIG --group $SECTION --key $KEY $new_value &
    echo "new value: $new_value"

    # Apply changes
    echo "Reloading..."
    kwriteconfig6 --file kwinrc --group Plugins --key "$ENABLEKEY" false &
    qdbus-qt6 org.kde.KWin /KWin reconfigure &
    sleep 0.2
    wait
    kwriteconfig6 --file kwinrc --group Plugins --key "$ENABLEKEY" true
    qdbus-qt6 org.kde.KWin /KWin reconfigure

    echo "Karousel Centered is Toggled."
else
    echo "Karousel is currently disabled. Cannot run command."
fi




