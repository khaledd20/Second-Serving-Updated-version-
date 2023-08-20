import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secondserving/services/firebase_auth_service.dart';

import 'messages_screen.dart';

class ChatHistoryScreen extends StatelessWidget {
  final CollectionReference chatsCollection =
      FirebaseFirestore.instance.collection('chats');

  String uid = "";
  User? user = FirebaseAuth.instance.currentUser;
  FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    if (user != null) {
      uid = user!.uid;
    }
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: Text('Chats', style: TextStyle(color: Colors.black)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatsCollection
            .where('participants', arrayContains: currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (snapshot.hasData) {
            final chats = snapshot.data!.docs;

            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final lastMessage = chat.get('lastMessage');

                return FutureBuilder<String>(
                  future: _firebaseAuthService.getUserName(
                      (user!.uid != chat.get('participants')[0])
                          ? chat.get('participants')[0]
                          : chat.get('participants')[1]),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    String contactName = '';
                    String receiverUID = '';
                    if (snapshot.hasData) {
                      contactName = snapshot.data!;
                      receiverUID = (user!.uid != chat.get('participants')[0])
                          ? chat.get('participants')[0]
                          : chat.get('participants')[1];
                    } else if (snapshot.hasError) {
                      // Handle the error here
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(contactName),
                      subtitle: Text(lastMessage),
                      onTap: () {
                        // Handle chat item tap
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  MessagesScreen(receiverUID: receiverUID)),
                        );
                      },
                    );
                  },
                );
              },
            );
          }

          return Text('No chats available.');
        },
      ),
    );
  }
}
