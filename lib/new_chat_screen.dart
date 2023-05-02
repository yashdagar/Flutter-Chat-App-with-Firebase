import 'package:Chat/utils/user_list.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'models/User.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({Key? key}) : super(key: key);

  @override
  State<NewChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<NewChatScreen> {

  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  IconData searchIcon = Icons.search_rounded;
  late final List<User1> users = [];

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      appBar: AppBar(
        title: isSearching?TextField(
          controller: searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search...',
          ),
          onSubmitted: (value)async {

            users.clear();

            String text = searchController.text.trim();

            if(text.isEmpty) {
              return;
            }

            DatabaseReference usersRef = FirebaseDatabase.instance.ref("Users");
            DatabaseEvent event = await usersRef.orderByChild('username')
                .startAt(text).endAt(text + '\uf8ff').once();
            for (var snapshot in event.snapshot.children) {
              User1 newUser = User1.getFromSnapshot(snapshot);
              if (!users.any((user) => user.key == newUser.key)) {
                setState(() {
                  users.add(newUser);
                });
              }
            }
          },
        ):const Text("New Chat"),
        actions: <Widget>[IconButton(
          icon: Icon(searchIcon),
          onPressed: () {
            setState(() {
              if (searchIcon == Icons.search) {
                searchIcon = Icons.close;
                isSearching = true;
              } else {
                searchIcon =Icons.search;
                isSearching = false;
                searchController.clear();
              }
            });
          },
        )],
      ),
        body: UserList(users:users, wantChats: false)
    );
  }
}