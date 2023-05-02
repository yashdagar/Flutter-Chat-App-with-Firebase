import 'dart:convert';
import 'package:Chat/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:http/http.dart' as http;
import 'package:Chat/utils/chat_message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/User.dart';
import 'models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override State<StatefulWidget> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  var textFieldController = TextEditingController();
  final scrollController = ScrollController();
  Iterable<Message> chatMessages = [];
  bool doesChatExist = false;
  User1? user;
  int messageAmount = 25, maxAmount = 500;
  bool isLoadingMore = false;
  int currentPage = 1;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    user = ModalRoute.of(context)!.settings.arguments as User1;
    CollectionReference messages =
    FirebaseFirestore.instance.collection('messages').doc(assignUsers(FirebaseAuth.instance.currentUser
    !.uid, user!.key)).collection("chats");

    getMaxAmount();

    checkChatExists(user!.key);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.settings.name == "/main");
                currentRoute = "/main";
              },
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            Stack(
              children: [const CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage('https://placekitten.com/640/360'),
            ),
                user!.online?Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ):const SizedBox(),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              user!.username,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: StreamBuilder<QuerySnapshot>(
            stream:
            messages.orderBy("timestamp",descending: true)
                .limit(messageAmount).snapshots(),
            builder: (BuildContext context,
                AsyncSnapshot<QuerySnapshot> snapshots) {
              if (snapshots.hasError) {
                return const SizedBox();
              }
              if (snapshots.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              chatMessages = snapshots.data!.docs.map((e) {
                return Message.fromSnapshot(e);
              });

              return ListView.builder(
                reverse: true,
                key: const Key('chat_messages_list'),
                physics: const ClampingScrollPhysics(),
                controller: scrollController,
                itemCount: chatMessages.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (BuildContext context, int index) {
                  if (index == chatMessages.length) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }else {
                    return ChatMessage(
                    message: chatMessages.elementAt(index),
                    isMe: chatMessages.elementAt(index).sender ==
                        FirebaseAuth.instance.currentUser?.uid,
                    previousMessage: index + 1 < chatMessages.length
                        ? chatMessages.elementAt(index+1).timestamp
                        : null,
                      isFirstMessage: chatMessages.length == index + 1,
                      isLastMessage: index == 0,
                  );
                  }
                },
              );
            }
          )),
          const SizedBox(height: 8),
          Container(
              padding: const EdgeInsets.only(left: 8.0),
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant, width: 1),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      controller: textFieldController,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      String message = (textFieldController.text.trim());
                      if (message.isNotEmpty) {

                        FirebaseDatabase.instance.ref("Users")
                            .child(FirebaseAuth.instance.currentUser!.uid).child("chats")
                            .child("personal").child(user!.key)
                            .set(ServerValue.timestamp);
                        FirebaseDatabase.instance.ref("Users")
                            .child(user!.key).child("chats")
                            .child("personal").child(FirebaseAuth.instance.currentUser!.uid)
                            .set(ServerValue.timestamp);
                        doesChatExist = true;
                        messages.add(
                          Message(
                              message: message,
                              isRead: false,
                              timestamp: DateTime.now().millisecondsSinceEpoch,
                            sender: FirebaseAuth.instance.currentUser!.uid
                          ).toJson()
                        );
                        if (defaultTargetPlatform == TargetPlatform.android) {
                          sendPushNotification(
                            title: "${FirebaseAuth.instance.currentUser!.displayName!}/${FirebaseAuth.instance.currentUser!.uid}",
                            body: message,
                            token: user!.fcmToken,
                          );
                        }
                        textFieldController.clear();
                      }
                    },
                  ),
                ]),
              ))
        ],
      ),
    );
  }

  checkChatExists (String user) async {
    DatabaseEvent event = await FirebaseDatabase.instance.ref("Users")
        .child(FirebaseAuth.instance.currentUser!.uid).child("chats")
        .child("personal").once();

    bool val = false;
    if(!event.snapshot.exists || event.snapshot.children.isEmpty){
      return;
    }
    for (var key in event.snapshot.children) {
      if(key.key == user){
        val = true;
      }
    }
    doesChatExist = val;
  }

  getMaxAmount() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(assignUsers(FirebaseAuth.instance.currentUser!.uid, user!.key))
        .collection("chats").get();
    maxAmount = snapshot.docs.length;
  }

  @override void initState() {
    super.initState();

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        if (messageAmount + 10 < maxAmount) {
          setState(() {
            messageAmount += 10;
          });
        }else if(messageAmount < maxAmount && (messageAmount + 10) > maxAmount){
          setState(() {
            messageAmount = maxAmount;
          });
        }
      }
    });
  }

  @override void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

bool checkIfShouldSendNotifications(RemoteNotification notification){
  if(ChatScreenState().user != null) {
    return notification.title!.split("/")[0] != ChatScreenState().user!.username
        && notification.title!.split("/")[0] !=
            FirebaseAuth.instance.currentUser!.displayName;
  }else {
    return false;
  }
}

void sendPushNotification({required String body, required String title, required String token}) async {

  try {
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization':
        'key=AAAAlOiX1Lk:APA91bGIKvUK96G6biZqwAZD43xFJwsRGZQ5dSbGCmNHVl8DIn5TdoMeN-dTvgONxdS40wkkhLXo5LQiSfOFoM4vZ3gdjMAoBqGC6F9jaiyAcfKFiavboqaEeTE--5ydeogbBmvEOwnI',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': body,
            'title': title,
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done'
          },
          "to": token,
        },
      ),
    );
  }catch (e){/**/}
}

String assignUsers(String user1,String user2) {
  int compareValue = user1.compareTo(user2);

  if (compareValue < 0) {
    return "$user1,$user2";
  } else if (compareValue > 0) {
    return "$user2,$user1";
  } else {
    return "$user1,$user2";
  }
}

isNewDay(bool isFirst, int? lastMessage, int message) {
  var messageDate = DateTime.fromMillisecondsSinceEpoch(message);
  var lastMessageDate = !isFirst?DateTime.fromMillisecondsSinceEpoch(lastMessage!):null;
  if(isFirst || lastMessage == null) {
    return true;
  }else if(messageDate.year != lastMessageDate!.year ||
      messageDate.month != lastMessageDate.month ||
      messageDate.day != lastMessageDate.day){
    return true;
  }
  else {
    return false;
  }
}