import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationPermissionAlert {
  static showBasicAlert(
    BuildContext context,
    bool isAllowed,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xfffbfbfb),
        title: Text('Get Notified!',
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Allow Awesome Notifications to send you beautiful notifications!',
              maxLines: 4,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Later',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              )),
          TextButton(
            onPressed: () async {
              isAllowed = await AwesomeNotifications()
                  .requestPermissionToSendNotifications();
              Navigator.pop(context);
            },
            child: Text(
              'Allow',
              style: TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static showScheduledAlert({
    required String? channelKey,
    required BuildContext context,
    required List<NotificationPermission> lockedPermissions,
    required List<NotificationPermission> permissionsAllowed,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xfffbfbfb),
        title: Text(
          'Awesome Notificaitons needs your permission',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'To proceede, you need to enable the permissions above' +
                  (channelKey?.isEmpty ?? true
                      ? ''
                      : ' on channel $channelKey') +
                  ':',
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5),
            Text(
              lockedPermissions
                  .join(', ')
                  .replaceAll('NotificationPermission.', ''),
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Deny',
                style: TextStyle(color: Colors.red, fontSize: 18),
              )),
          TextButton(
            onPressed: () async {
              // Request the permission through native resources. Only one page redirection is done at this point.
              await AwesomeNotifications().requestPermissionToSendNotifications(
                  channelKey: channelKey, permissions: lockedPermissions);

              // After the user come back, check if the permissions has successfully enabled
              permissionsAllowed = await AwesomeNotifications()
                  .checkPermissionList(
                      channelKey: channelKey, permissions: lockedPermissions);

              Navigator.pop(context);
            },
            child: Text(
              'Allow',
              style: TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
