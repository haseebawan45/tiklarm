#!/bin/bash

# Path to the flutter_local_notifications plugin
NOTIFICATION_PLUGIN_PATH="$HOME/.pub-cache/hosted/pub.dev/flutter_local_notifications-14.1.5/android/src/main/java/com/dexterous/flutterlocalnotifications/FlutterLocalNotificationsPlugin.java"

# Apply the ambiguous method fix
if [ -f "$NOTIFICATION_PLUGIN_PATH" ]; then
  sed -i 's/bigPictureStyle.bigLargeIcon(null);/bigPictureStyle.bigLargeIcon((Bitmap) null);/g' "$NOTIFICATION_PLUGIN_PATH"
  echo "Applied fix to flutter_local_notifications plugin"
else
  echo "Could not find flutter_local_notifications plugin at $NOTIFICATION_PLUGIN_PATH"
fi

echo "Patches applied successfully" 