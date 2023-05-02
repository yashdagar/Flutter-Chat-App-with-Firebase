import 'dart:async';
import 'package:Chat/models/chat.dart';
import 'package:Chat/utils/user_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'models/User.dart';

List<User1> users = [];
List<Chat> chats = [];
List<StreamSubscription> subscriptions = [];
String text = "";
final userListKey = GlobalKey<UserListState>();

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {

  @override initState() {

    FirebaseDatabase.instance.ref("Users")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("online").onDisconnect().set(false);
    FirebaseDatabase.instance.ref("Users")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("online").set(true);

    updateToken();
    getData();

    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(title),
        backgroundColor: Theme
            .of(context)
            .colorScheme.background,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout_outlined,color: Theme.of(context).colorScheme.onBackground),
            onPressed: () async {
              FirebaseDatabase.instance.ref("Users")
                  .child(FirebaseAuth.instance.currentUser!.uid)
                  .child("online").set(false);
              await FirebaseAuth.instance.signOut();
              currentRoute = "/login";
              await Navigator.of(context).pushReplacementNamed("/login");
            },
            color: Theme.of(context).primaryColor
          )
        ]
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: UserList(users: users, key: userListKey, wantChats: true)
        )
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Navigator.of(context).pushNamed("/main/new");
          },
        shape: const CircleBorder(),
        child: const Icon(Icons.messenger),
      ),
    );
  }

  getData() async {
    FirebaseDatabase.instance.ref("Users")
        .child(FirebaseAuth.instance.currentUser!.uid).child("chats")
        .child("personal").limitToFirst(15).onValue.listen((event) {
      for (DataSnapshot snapshot in event.snapshot.children){
        if(!chats.any((chat) => chat.id == snapshot.key
            && chat.timestamp == snapshot.value as int)) {
          Chat newChat = Chat(snapshot.value as int, snapshot.key!);
          chats.add(newChat);
          chats.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          subscriptions.add(FirebaseDatabase.instance.ref("Users")
              .child(newChat.id).onValue.listen((event) async {
            User1 newUser = User1.getFromSnapshot(event.snapshot);
            if(!users.any((user) => user.key == newUser.key)){
              if (userListKey.currentState?.mounted ?? false) {
                userListKey.currentState?.setState(() {
                  users.add(newUser);
                  users.sort((a, b) {
                    int indexA = chats.indexWhere((chat) =>
                    chat.id.toString() == a.key);
                    int indexB = chats.indexWhere((chat) =>
                    chat.id.toString() == b.key);
                    return indexA.compareTo(indexB);
                  });
                });
              }else{if (kDebugMode) {print("doesn't exist");}}
            }else{
              int index = users.indexWhere((user) => user.key == newUser.key);
              if (userListKey.currentState?.mounted ?? false) {
                userListKey.currentState?.setState(() {
                  users[index] = newUser;
                  users.sort((a, b) {
                    int indexA = chats.indexWhere((chat) =>
                    chat.id.toString() == a.key);
                    int indexB = chats.indexWhere((chat) =>
                    chat.id.toString() == b.key);
                    return indexA.compareTo(indexB);
                  });
                });
              }
            }
          }));
        }
        else if(chats.any((chat) => chat.id == snapshot.key
            && chat.timestamp != snapshot.value as int)){
          int index = chats.indexWhere((chat) => chat.id == snapshot.key
              && chat.timestamp != snapshot.value as int);
          chats[index] = Chat(snapshot.value as int, snapshot.key!);

          if (userListKey.currentState?.mounted ?? false) {
            userListKey.currentState?.setState(() {
              users.sort((a, b) {
                int indexA = chats.indexWhere((chat) =>
                chat.id.toString() == a.key);
                int indexB = chats.indexWhere((chat) =>
                chat.id.toString() == b.key);
                return indexA.compareTo(indexB);
              });
            });
          }else{if (kDebugMode) {print("doesn't exist");}}
        }
      }
    });
  }

  @override void dispose(){
    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  updateToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    FirebaseDatabase.instance.ref("Users")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("fcmToken").set(fcmToken);
  }
}

String getKey(String string,String substring) {
  List<String> subStrings = string.split(",");
  if(subStrings.first == substring){
    return subStrings[1];
  }
  else {
    return subStrings.first;
  }
}