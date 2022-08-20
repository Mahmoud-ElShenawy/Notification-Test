import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_app/notification_handler/notification_permission_alert.dart';
import 'package:awesome_notifications/android_foreground_service.dart';
import 'package:rxdart/subjects.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

import 'dart:io';
import 'dart:ui';

import 'notification_entity.dart';

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._init();

  NotificationHandler._init();

  static NotificationHandler get instance => _instance;

  final String CHANNEL_NAME = 'Test Notification';
  final String CHANNEL_DESC = 'Test Notification Description';
  final String CHANNEL_KEY = 'test_channel';
  final String CHANNEL_KEY_GROUP = 'test_channel_group';
  final String CHANNEL_NAME_GROUP = 'Test Notification Group';

  final String ICON_PATH = 'resource://drawable/app_icon.png';

  String localTimeZone = '';
  String utcTimeZone = '';

  init() async {
    localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
    utcTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();

    AwesomeNotifications().initialize(
      'resource://mipmap/ic_launcher',
      [
        NotificationChannel(
          channelGroupKey: CHANNEL_KEY_GROUP,
          channelKey: CHANNEL_KEY,
          channelName: CHANNEL_NAME,
          channelDescription: CHANNEL_DESC,
          enableVibration: true,
          playSound: true,
          channelShowBadge: true,
          defaultPrivacy: NotificationPrivacy.Public,
          importance: NotificationImportance.Max,
        )
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupkey: CHANNEL_KEY_GROUP,
          channelGroupName: CHANNEL_NAME_GROUP,
        )
      ],
      debug: true,
    );
  }

  Future<bool> redirectToPermissionsPage() async {
    await AwesomeNotifications().showNotificationConfigPage();
    return await AwesomeNotifications().isNotificationAllowed();
  }

  Future<void> redirectToBasicChannelPage() async {
    await AwesomeNotifications().showNotificationConfigPage(
      channelKey: CHANNEL_KEY,
    );
  }

  Future<void> redirectToAlarmPage() async {
    await AwesomeNotifications().showAlarmPage();
  }

  Future<void> redirectToScheduledChannelsPage() async {
    await AwesomeNotifications().showNotificationConfigPage(
      channelKey: CHANNEL_KEY,
    );
  }

  Future<int> getBadgeIndicator() async {
    int amount = await AwesomeNotifications().getGlobalBadgeCounter();
    return amount;
  }

  Future<void> setBadgeIndicator(int amount) async {
    await AwesomeNotifications().setGlobalBadgeCounter(amount);
  }

  Future<int> incrementBadgeIndicator() async {
    return await AwesomeNotifications().incrementGlobalBadgeCounter();
  }

  static Future<void> redirectToOverrideDndPage() async {
    await AwesomeNotifications().showGlobalDndOverridePage();
  }

  Future<int> decrementBadgeIndicator() async {
    return await AwesomeNotifications().decrementGlobalBadgeCounter();
  }

  Future<void> resetBadgeIndicator() async {
    await AwesomeNotifications().resetGlobalBadge();
  }

  Future<void> stopForegroundServiceNotification() async {
    await AndroidForegroundService.stopForeground();
  }

  static Future<bool> requestBasicPermissionToSendNotifications(
      BuildContext context) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await NotificationPermissionAlert.showBasicAlert(
        context,
        isAllowed,
      );
    }
    return isAllowed;
  }

  Future<void> requestFullScheduleChannelPermissions(
    BuildContext context,
    List<NotificationPermission> requestedPermissions,
  ) async {
    await requestUserPermissions(
      context,
      channelKey: CHANNEL_KEY,
      permissionList: requestedPermissions,
    );
  }

  Future<List<NotificationPermission>> requestUserPermissions(
    BuildContext context, {
    // if you only intends to request the permissions until app level, set the channelKey value to null
    required String? channelKey,
    required List<NotificationPermission> permissionList,
  }) async {
    // Check if the basic permission was conceived by the user
    if (!await requestBasicPermissionToSendNotifications(context)) {
      return [];
    }

    // Check which of the permissions you need are allowed at this time
    List<NotificationPermission> permissionsAllowed =
        await AwesomeNotifications().checkPermissionList(
            channelKey: channelKey, permissions: permissionList);

    // If all permissions are allowed, there is nothing to do
    if (permissionsAllowed.length == permissionList.length) {
      return permissionsAllowed;
    }

    // Refresh the permission list with only the disallowed permissions
    List<NotificationPermission> permissionsNeeded =
        permissionList.toSet().difference(permissionsAllowed.toSet()).toList();

    // Check if some of the permissions needed request user's intervention to be enabled
    List<NotificationPermission> lockedPermissions =
        await AwesomeNotifications().shouldShowRationaleToRequest(
            channelKey: channelKey, permissions: permissionsNeeded);

    // If there is no permpermissionsAlloweditions depending of user's intervention, so request it directly
    if (lockedPermissions.isEmpty) {
      // Request the permission through native resources.
      await AwesomeNotifications().requestPermissionToSendNotifications(
          channelKey: channelKey, permissions: permissionsNeeded);

      // After the user come back, check if the permissions has successfully enabled
      permissionsAllowed = await AwesomeNotifications().checkPermissionList(
          channelKey: channelKey, permissions: permissionsNeeded);
    } else {
      // If you need to show a rationale to educate the user to conceed the permission, show it
      await NotificationPermissionAlert.showScheduledAlert(
        channelKey: channelKey,
        context: context,
        lockedPermissions: lockedPermissions,
        permissionsAllowed: permissionsAllowed,
      );
    }

    // Return the updated list of allowed permissions
    return permissionsAllowed;
  }

  Future<void> showBasicNotification(NotificationEntity entity) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: entity.id ?? 1,
        channelKey: CHANNEL_KEY,
        title: entity.title ?? '',
        body: entity.body ?? '',
      ),
    );
  }

  Future<void> showNotificationWithPayloadContent(
      NotificationEntity entity) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: entity.id ?? 1,
        channelKey: CHANNEL_KEY,
        title: entity.title ?? '',
        body: entity.body ?? '',
        payload: entity.payload ?? {},
      ),
    );
  }

  Future<void> scheduleNotifications(NotificationEntity entity) async {
    if (entity.schedules != null && (entity.schedules?.length ?? 0) != 0) {
      for (var i = 0; i < (entity.schedules?.length ?? 0); i++) {
        await AwesomeNotifications()
            .createNotification(
              content: NotificationContent(
                id: i,
                channelKey: CHANNEL_KEY,
                title: '${entity.title} $i',
                body: entity.body ?? '',
                payload: entity.payload ?? {},
                displayOnBackground: true,
                displayOnForeground: true,
                autoDismissible: true,
                locked: true,
                criticalAlert: true,
                wakeUpScreen: true,
                showWhen: true,
              ),
              schedule: NotificationCalendar.fromDate(
                date: entity.schedules![i],
                allowWhileIdle: true,
                preciseAlarm: true,
                repeats: true,
              ),
            )
            .then((value) => FlutterAppBadger.updateBadgeCount(i));
      }
    } else {
      debugPrint('There is not schedules to set up notifications');
    }
  }
}

class NotificationService {
  NotificationService();

  final text = Platform.isIOS;

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final BehaviorSubject<String> behaviorSubject = BehaviorSubject();

  Future<void> initializePlatformNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    tz.initializeTimeZones();
    tz.setLocalLocation(
      tz.getLocation(
        await FlutterNativeTimezone.getLocalTimezone(),
      ),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onSelectNotification: selectNotification,
    );
  }

  void onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    print('id $id');
  }

  void selectNotification(String? payload) {
    if (payload != null && payload.isNotEmpty) {
      behaviorSubject.add(payload);
    }
  }

  Future<NotificationDetails> _notificationDetails() async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'channel id',
      'channel name',
      groupKey: 'com.example.test_app',
      channelDescription: 'channel description',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
    );

    IOSNotificationDetails iosNotificationDetails = IOSNotificationDetails(
      threadIdentifier: "thread1",
    );

    final details = await _localNotifications.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      behaviorSubject.add(details.payload ?? '');
    }
    NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iosNotificationDetails);

    return platformChannelSpecifics;
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    final platformChannelSpecifics = await _notificationDetails();
    await _localNotifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> showScheduledLocalNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    required int seconds,
  }) async {
    final platformChannelSpecifics = await _notificationDetails();
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      platformChannelSpecifics,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }

  Future<void> showPeriodicLocalNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    final platformChannelSpecifics = await _notificationDetails();
    await _localNotifications.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.everyMinute,
      platformChannelSpecifics,
      payload: payload,
      androidAllowWhileIdle: true,
    );
  }
}
