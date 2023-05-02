import 'package:firebase_database/firebase_database.dart';

class User1 {
  String name;
  final String username;
  final String key;
  final String fcmToken;
  final bool online;
  final dynamic lastSeen;
  bool? isNameBold;

  User1({
    required this.name,
    required this.username,
    required this.online,
    required this.lastSeen,
    required this.key,
    required this.fcmToken,
    this.isNameBold,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'key': key,
      'online': online,
      'lastSeen': lastSeen,
      "fcmToken": fcmToken,
    };
  }

  factory User1.fromJson(Map<String, dynamic> json) {
    return User1(
      name: json['name'],
      username: json['username'],
      key: json['key'],
      online: json['online'],
      lastSeen: json['lastSeen'],
      fcmToken: json['fcmToken']
    );
  }

  static User1 getFromSnapshot(DataSnapshot snapshot) {
    return User1(
      name: snapshot.child("name").value.toString(),
      username: snapshot.child("username").value.toString(),
      key: snapshot.child("key").value.toString(),
      fcmToken: snapshot.child("fcmToken").value.toString(),
      online: snapshot.child("online").value as bool,
      lastSeen: snapshot.child("lastSeen").value as int,
    );
  }
}