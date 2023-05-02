import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String message;
  final bool isRead;
  final int timestamp;
  final String sender;
  final String? messageId;

  Message({
    required this.message,
    required this.isRead,
    required this.timestamp,
    required this.sender,
    this.messageId
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      message: json['message'],
      isRead: json['isRead'],
      timestamp: json['timestamp'],
      sender: json['sender'],
      messageId: json['messageId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'isRead': isRead,
      'timestamp': timestamp,
      'sender': sender,
      'messageId': messageId,
    };
  }

  static Message fromSnapshot(DocumentSnapshot object) {
    Map<String,dynamic> newMessage = object.data() as Map<String,dynamic>;
    return Message(
      message: newMessage["message"],
      isRead: newMessage["isRead"],
      timestamp: newMessage["timestamp"],
      sender: newMessage["sender"],
      messageId: object.id,
    );
  }
}