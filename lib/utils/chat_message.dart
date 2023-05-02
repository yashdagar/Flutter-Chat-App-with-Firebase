import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../chat_screen.dart';
import '../models/message.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatMessage extends StatelessWidget {
  final Message message;
  final bool isMe;
  final int? previousMessage;
  final bool isFirstMessage;
  final bool isLastMessage;

  const ChatMessage({
    Key? key,
    required this.message,
    required this.isMe,
    required this.previousMessage,
    required this.isFirstMessage,
    required this.isLastMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final messageContent = message.message;
    final timestamp = DateFormat.MMMMEEEEd()
        .format(DateTime.fromMillisecondsSinceEpoch(message.timestamp));

    if(!message.isRead && message.sender != FirebaseAuth.instance.currentUser!.uid){
      FirebaseFirestore.instance
          .collection("messages")
          .doc(assignUsers(
            FirebaseAuth.instance.currentUser!.uid,
            message.sender
          ))
          .collection("chats")
          .doc(message.messageId)
          .update(Message(
          message: messageContent,
          isRead: true,
          timestamp: message.timestamp,
          sender: message.sender
      ).toJson());
    }

    return Column(
      crossAxisAlignment:
      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (isNewDay(isFirstMessage, previousMessage, message.timestamp))
          Row(mainAxisAlignment: MainAxisAlignment.center,children: [
            Text(
              timestamp,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500
              ),
              textAlign: isMe?TextAlign.right:TextAlign.left,
            )]),
        InkWell(onTap: () async {
            var status = await Permission.storage.status;
            if (!status.isGranted) {
              status = await Permission.storage.request();
              if (!status.isGranted) {
                return;
              }
            }
            Uri? uri = getUri(messageContent);
            if (uri!= null && await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          }, child: Container(
            margin: const EdgeInsets.symmetric(vertical: 0.5, horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 48),
            decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isMe ?
            MediaQuery.of(context).platformBrightness == Brightness.light
                ? const Color(0xFF89CFF0)
                : const Color(0xFF4475CD)
              : MediaQuery.of(context).platformBrightness == Brightness.light
                ? const Color(0xFFAFDCEC)
                : const Color(0xFF6495ED)
        ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                    messageContent,
                    style: TextStyle(color: Theme.of(context).colorScheme.onBackground)
                ),
                const SizedBox(height: 2),
              ]
      )
        )),
        if(isLastMessage && isMe && message.isRead)
          Row(mainAxisAlignment: MainAxisAlignment.end,children: [
            Text(
              "Seen",
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400
              ),
              textAlign: TextAlign.right,
            ),const SizedBox(width: 8,)]),
      ]);
  }
  Uri? getUri(String text) {
    RegExp urlRegex = RegExp(r'(https?://[^\s]+)');
    Match? match = urlRegex.firstMatch(text);
    if (match != null) {
      String url = match.group(0)!;
      return Uri.parse(url);
    }
    return null;
  }
}