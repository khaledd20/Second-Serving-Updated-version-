import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesScreen extends StatefulWidget {
  final String receiverUID;
  final User? user = FirebaseAuth.instance.currentUser;
  final chatsCollection = FirebaseFirestore.instance.collection('chats');
  final usersCollection = FirebaseFirestore.instance.collection('users');

  MessagesScreen({required this.receiverUID});

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _textController = TextEditingController();

  void _sendMessage() async {
    final message = _textController.text.trim();

    if (message.isNotEmpty) {
      final querySnapshot =
          await widget.chatsCollection.where('chatId', arrayContainsAny: [
        '${widget.user!.uid}${widget.receiverUID}',
        '${widget.receiverUID}${widget.user!.uid}'
      ]).get();
      final docId = querySnapshot.docs.first.id;

      final senderNameSnapshot =
          await widget.usersCollection.doc(widget.user!.uid).get();
      final senderName = senderNameSnapshot.data()!['name'] ?? '';
      await widget.chatsCollection.doc(docId).update({
        'lastMessage': message,
      }).catchError((error) {
        print('Error updating chat collection field lastMessage: $error');
      });
      await widget.chatsCollection.doc(docId).collection('messages').add({
        'sender': senderName,
        'text': message,
        'timestamp': Timestamp.now(),
        'uid': widget.user!.uid,
      }).catchError((error) {
        print('Error sending message: $error');
      });

      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: Text('Messages', style: TextStyle(color: Colors.black)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.chatsCollection.where('chatId', arrayContainsAny: [
                '${widget.user!.uid}${widget.receiverUID}',
                '${widget.receiverUID}${widget.user!.uid}'
              ]).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final chatDocs = snapshot.data!.docs;
                if (chatDocs.isEmpty) {
                  return Center(
                    child: Text('No messages found.'),
                  );
                }

                final chatDoc = chatDocs.first;
                final messagesCollection = widget.chatsCollection
                    .doc(chatDoc.id)
                    .collection('messages');

                return StreamBuilder<QuerySnapshot>(
                  stream: messagesCollection
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final messages = snapshot.data!.docs;

                    if (messages.isEmpty) {
                      return Center(
                        child: Text('No messages found.'),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message =
                            messages[index].data() as Map<String, dynamic>?;
                        final sender = message?['sender'];
                        final text = message?['text'];
                        final uid = message?['uid'];

                        return Bubble(
                          sender: sender ?? 'null',
                          text: text ?? 'null',
                          uid: uid ?? 'null',
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Enter a message',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Bubble extends StatelessWidget {
  final String sender;
  final String text;
  final String uid;
  const Bubble({required this.sender, required this.text, required this.uid});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUser = uid == currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: isCurrentUser ? Alignment.topRight : Alignment.topLeft,
        child: Container(
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.blue : Colors.green,
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: isCurrentUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                sender,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
