# Path to the flutter_local_notifications plugin
$NOTIFICATION_PLUGIN_PATH = "$env:USERPROFILE\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_local_notifications-14.1.5\android\src\main\java\com\dexterous\flutterlocalnotifications\FlutterLocalNotificationsPlugin.java"

# Apply the ambiguous method fix
if (Test-Path $NOTIFICATION_PLUGIN_PATH) {
    $content = Get-Content $NOTIFICATION_PLUGIN_PATH -Raw
    $content = $content -replace "bigPictureStyle.bigLargeIcon\(null\);", "bigPictureStyle.bigLargeIcon((Bitmap) null);"
    Set-Content -Path $NOTIFICATION_PLUGIN_PATH -Value $content
    Write-Host "Applied fix to flutter_local_notifications plugin"
} else {
    Write-Host "Could not find flutter_local_notifications plugin at $NOTIFICATION_PLUGIN_PATH"
}

Write-Host "Patches applied successfully" 