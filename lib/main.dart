import 'dart:async';

import 'package:Chat/fcm_reciever.dart';
import 'package:Chat/models/User.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'chat_screen.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'main_screen.dart';
import 'new_chat_screen.dart';

Future<void> main() async => runApp(const MyApp(user: null));

const title = "Chat";
User1? _user;
String currentRoute = "";

class MyApp extends StatelessWidget {

  final User1? user;

  const MyApp({Key? key,required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
      builder: (context, snapshot) {
        _user = user;

        if (snapshot.connectionState == ConnectionState.done) {
          return const Main();
        } else {
          return Column();
        }
      });
  }
}

class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {

  ColorScheme lightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF00658B),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFC5E7FF),
    onPrimaryContainer: Color(0xFF001E2D),
    secondary: Color(0xFF4E616D),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD1E5F4),
    onSecondaryContainer: Color(0xFF0A1E28),
    tertiary: Color(0xFF615A7C),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE7DEFF),
    onTertiaryContainer: Color(0xFF1D1735),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
    onError: Color(0xFFFFFFFF),
    onErrorContainer: Color(0xFF410002),
    background: Color(0xFFFBFCFF),
    onBackground: Color(0xFF191C1E),
    surface: Color(0xFFFBFCFF),
    onSurface: Color(0xFF191C1E),
    surfaceVariant: Color(0xFFDDE3EA),
    onSurfaceVariant: Color(0xFF41484D),
    outline: Color(0xFF71787E),
    onInverseSurface: Color(0xFFF0F1F3),
    inverseSurface: Color(0xFF2E3133),
    inversePrimary: Color(0xFF7ED0FF),
    shadow: Color(0xFF000000),
    surfaceTint: Color(0xFF00658B),
    outlineVariant: Color(0xFFC1C7CD),
    scrim: Color(0xFF000000),
  );

  ColorScheme darkColorScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7ED0FF),
    onPrimary: Color(0xFF00344A),
    primaryContainer: Color(0xFF004C6A),
    onPrimaryContainer: Color(0xFFC5E7FF),
    secondary: Color(0xFFB6C9D8),
    onSecondary: Color(0xFF20333E),
    secondaryContainer: Color(0xFF374955),
    onSecondaryContainer: Color(0xFFD1E5F4),
    tertiary: Color(0xFFCBC1E9),
    onTertiary: Color(0xFF322C4C),
    tertiaryContainer: Color(0xFF494263),
    onTertiaryContainer: Color(0xFFE7DEFF),
    error: Color(0xFFFFB4AB),
    errorContainer: Color(0xFF93000A),
    onError: Color(0xFF690005),
    onErrorContainer: Color(0xFFFFDAD6),
    background: Color(0xFF000000),// FF191C1E
    onBackground: Color(0xFFE1E2E5),
    surface: Color(0xFF000000), // FF191C1E
    onSurface: Color(0xFFE1E2E5),
    surfaceVariant: Color(0xFF41484D),
    onSurfaceVariant: Color(0xFFC1C7CD),
    outline: Color(0xFF8B9297),
    onInverseSurface: Color(0xFF191C1E),
    inverseSurface: Color(0xFFE1E2E5),
    inversePrimary: Color(0xFF00658B),
    shadow: Color(0xFF000000),
    surfaceTint: Color(0xFF7ED0FF),
    outlineVariant: Color(0xFF41484D),
    scrim: Color(0xFF000000),
  );

  late StreamSubscription notificationSub;

  @override
  Widget build(BuildContext context) {

    currentRoute = FirebaseAuth.instance.currentUser!= null?'/main':'/login';

    return MaterialApp(
      title: 'Chat',
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),

      initialRoute: _user != null? "/chat":
      FirebaseAuth.instance.currentUser!= null?'/main':'/login',
      routes: {
        '/login': (context) => const AuthPage(),
        '/main': (context) => const MainScreen(),
        '/chat': (context) => const ChatScreen(),
        "/main/new": (context) => const NewChatScreen(),
      },
      onGenerateInitialRoutes: (String initialRouteName) {
        if(initialRouteName == "/chat"){
          return [MaterialPageRoute(
            settings: RouteSettings(name: "/chat", arguments: _user),
            builder: (BuildContext context) => const ChatScreen(),
          )];
        }else{
          return [MaterialPageRoute(
            settings: RouteSettings(name: initialRouteName),
            builder: (BuildContext context) => initialRouteName == "/main"
                ? const MainScreen()
            : const AuthPage(),
          )];
        }
      },
    );
  }

  @override void initState() {
    super.initState();

    notificationSub = FirebaseMessaging.onMessage.listen((message) async {
      RemoteNotification? notification = message.notification;

      User1? user;

      await FirebaseDatabase.instance.ref("Users")
          .child(notification!.title!.split("/")[1]).once().then((event) {
        user = User1(
          name: event.snapshot.child("name").value.toString(),
          username: event.snapshot.child("username").value.toString(),
          key: event.snapshot.child("key").value.toString(),
          fcmToken: event.snapshot.child("fcmToken").value.toString(),
          online: event.snapshot.child("online").value as bool,
          lastSeen: event.snapshot.child("lastSeen").value as int,
        );
      });

      if(mounted && (currentRoute!= "/chat" || checkIfShouldSendNotifications(notification))) {
        ElegantNotification(
            width: MediaQuery
                .of(context)
                .size
                .width,
            notificationPosition: NotificationPosition.topCenter,
            animation: AnimationType.fromTop,
            title: Text(notification.title!.split("/")[0],),
            description: Text(notification.body!,),
            icon: const SizedBox(),
            background: Theme
                .of(context)
                .colorScheme
                .background,
            showProgressIndicator: false,
            onTap: () {
              if (user != null) {
                Navigator.of(context).popAndPushNamed("/chat", arguments: user);
              }
            }
        ).show(context);
      }
    });

    FcmReceiver().init();
    FirebaseMessaging.onBackgroundMessage((message) =>
        FcmReceiver().onBackgroundMessage(message, context));
  }
}