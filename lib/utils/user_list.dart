import 'package:Chat/main.dart';
import 'package:Chat/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../chat_screen.dart';
import '../models/User.dart';

late String messageOrName;
FontWeight textWeight = FontWeight.w200;

class UserList extends StatefulWidget {
  final List<User1> users;
  final bool wantChats;

  const UserList({super.key, required this.users, required this.wantChats});

  @override
  State<UserList> createState() => UserListState(users, wantChats);
}

class UserListState extends State<UserList>{
  final List<User1> users;
  final bool wantChats;

  UserListState(this.users, this.wantChats);

  @override
  Widget build(BuildContext context) {

    return ListView.builder(
      itemCount: users.length,
      physics: const ClampingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {

        if(wantChats) getData(users[index]);

        messageOrName = users[index].name;
        if(messageOrName.length > 25){
          messageOrName = "${messageOrName.substring(0,23)}...";
        }

        if(users[index].isNameBold != null){
          if (users[index].isNameBold!){
            textWeight = FontWeight.w400;
          }else{
            textWeight = FontWeight.w200;
          }
        }

        return
          users[index].key!=FirebaseAuth.instance.currentUser!.uid?
          Column(children: [
            InkWell(
                onTap: () async {
                  currentRoute = "/chat";
                  await Navigator.of(context).pushNamed('/chat', arguments: users[index]);
                },
                child:Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(mainAxisSize: MainAxisSize.max,children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Stack(children: [
                            const CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage('https://placekitten.com/640/360'),
                            ),
                            users[index].online?Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                    width: 12,
                                    height: 12,
                                    padding: const EdgeInsets.all(1),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.background,
                                      shape: BoxShape.circle,
                                    ),child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0x8822EE44),
                                    shape: BoxShape.circle,
                                  ),
                                )
                                )
                            ):const SizedBox(),
                          ],
                          )
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
                        Text(users[index].username,style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16
                        )),
                        const SizedBox(height: 4),
                        Text(messageOrName, style: TextStyle(
                            fontWeight: textWeight,
                            fontSize: 14
                        )),
                      ])
                    ]))),
            Container(
                width: MediaQuery.of(context).size.width,
                height: 0.5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                )),
          ])
              :const SizedBox();
      },
    );
  }

  getData (User1 user) async {
    List<Message> messages = [];
    try {
      QuerySnapshot snapshots = await FirebaseFirestore.instance
          .collection('messages')
          .doc(assignUsers(FirebaseAuth.instance.currentUser!.uid, user.key))
          .collection("chats").limit(10).orderBy("timestamp", descending: false)
          .get();
      messages = snapshots.docs.map((e) {
        return Message.fromSnapshot(e);
      }).toList();
    }catch(e){ if (kDebugMode) print(e);}

    int i = 0;
    for (Message message in messages){
      if(!message.isRead
          && message.sender != FirebaseAuth.instance.currentUser!.uid) i++;
    }
    String str = "";
    if(i==0){
      if(messages.isNotEmpty) {
        str = messages.last.message;
        user.isNameBold = false;
      }else {
        str = user.name;
        user.isNameBold = false;
      }
    }else if(i==10){
      str = "9+ unread messages";
      user.isNameBold = true;
    }else{
      str = "$i unread messages";
      user.isNameBold = true;
    }
    setState(() {
        users[users.indexWhere((user1) => user1.key == user.key)].name = str;
        users[users.indexWhere((user1) => user1.key == user.key)]
            .isNameBold = user.isNameBold;
    });
  }
}