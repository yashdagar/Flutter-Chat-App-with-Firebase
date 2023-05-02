import 'dart:async';
import 'package:Chat/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmReceiver {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/logo');
  late AndroidNotificationChannelGroup channelGroup;
  int id = 1;

  Future<void> init() async {
    await firebaseMessaging.requestPermission();
  }

  onBackgroundMessage(RemoteMessage message, BuildContext context) async {
    RemoteNotification? notification = message.notification;

    if (notification != null
        && notification.title != null
        && notification.body != null) {
      String username = notification.title!.split("/")[0];
      // String key = notification.title!.split("/")[1];

      var initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (
              NotificationResponse notificationResponse) async {
            if (notificationResponse.notificationResponseType ==
                NotificationResponseType.selectedNotification) {
              runApp(const MyApp(user:null));
            }
          }
      );

      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
          id.toString(), 'chat',
          importance: Importance.max, priority: Priority.high);
      id++;
      var platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      channelGroup = AndroidNotificationChannelGroup(
          'com.example.newfluuter15042023', username);
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannelGroup(channelGroup);

      await flutterLocalNotificationsPlugin.show(
          id,
          username,
          notification.body,
          platformChannelSpecifics,
          payload: username
      );
    }
  }
}