import 'package:flutter/material.dart';
import 'package:secondserving/views/report_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/meal_model.dart';
import 'food_shared_screen.dart';
import 'messages_screen.dart';

class MealDetailsScreen extends StatefulWidget {
  final Meal meal;
  final User? user = FirebaseAuth.instance.currentUser;
  final chatsCollection = FirebaseFirestore.instance.collection('chats');
  final usersCollection = FirebaseFirestore.instance.collection('users');
  late DocumentReference? _currentChatRef;
  MealDetailsScreen({required this.meal});

  @override
  _MealDetailsScreenState createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  void _launchGoogleMaps(String coordinates) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$coordinates';
    try {
      await launch(
        url,
        forceWebView: true,
        enableJavaScript: true, // Enable JavaScript support
      );
    } catch (e) {
      print('Error launching Google Maps website: $e');
      // Handle the error gracefully or show an error message to the user
    }
  }

  void _uploadData(String mealId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> mealDoc =
          await FirebaseFirestore.instance
              .collection('meals')
              .doc(mealId)
              .get();

      final String mealStatus = mealDoc.data()?['status'] ?? '';

      if (mealStatus == 'booked') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meal is already booked!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

        await FirebaseFirestore.instance
            .collection('meals')
            .doc(mealId)
            .update({
          'status': 'booked',
          'receiverID': userId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meal booked successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error updating meal status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book the meal. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _getCurrentChat() async {
    final querySnapshot =
        await widget.chatsCollection.where('chatId', arrayContainsAny: [
      '${widget.user!.uid}${widget.meal.donorId}',
      '${widget.meal.donorId}${widget.user!.uid}'
    ]).get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        widget._currentChatRef = querySnapshot.docs.first.reference;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                MessagesScreen(receiverUID: widget.meal.donorId)),
      );
    } else {
      final newChatDoc = await widget.chatsCollection.add({
        'currentUserId': widget.user!.uid,
        'peerId': widget.meal.donorId,
        'participants': [widget.user!.uid, widget.meal.donorId],
        'chatId': [
          '${widget.meal.donorId}${widget.user!.uid}',
          '${widget.meal.donorId}${widget.user!.uid}'
        ],
        'lastMessage': '',
      });

      setState(() {
        widget._currentChatRef = newChatDoc;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                MessagesScreen(receiverUID: widget.meal.donorId)),
      );
    }
  }

  void _navigateToReportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportScreen(
            mealId: widget.meal.mealId), // Access mealId from widget.meal
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(widget.meal.name, style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(
              widget.meal.photo,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Name:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                        onPressed: _navigateToReportScreen,
                        style: ButtonStyle(),
                        child:
                            Text('Report', style: TextStyle(color: Colors.red)))
                  ],
                ),
                Text(
                  widget.meal.name,
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 8),
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.meal.description,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Location:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.meal.location,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Status:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.meal.status,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.meal.donorId != widget.user!.uid)
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement chat functionality

                          _getCurrentChat();
                        },
                        child:
                            Text('Chat', style: TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(primary: Colors.white),
                      ),
                    ElevatedButton(
                      onPressed: () {
                        _launchGoogleMaps(widget.meal.location);
                      },
                      child: Column(
                          children: [Icon(Icons.map), Text('Google Map')]),
                      style:
                          ElevatedButton.styleFrom(primary: Color(0xffbcdfa6)),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                if (widget.meal.donorId != widget.user!.uid)
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        _uploadData(widget.meal.mealId);
                      },
                      child: Text('Book'),
                      style: ButtonStyle(
                        minimumSize: MaterialStateProperty.all<Size>(
                            Size(200, 35.0)), // Set the button width
                        backgroundColor: MaterialStateProperty.all<Color>(Color(
                            0xff14c81cb)), // Set the button background color
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
