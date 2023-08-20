import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secondserving/views/share_meal_screen.dart';
import '../models/meal_model.dart';
import 'chat_history_screen.dart';
import 'profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'meal_details.dart' as meal_details;
import 'history.dart' as history;

import 'messages_screen.dart';

class FoodReceiverScreen extends StatefulWidget {
  const FoodReceiverScreen({Key? key}) : super(key: key);

  @override
  _FoodReceiverScreenState createState() => _FoodReceiverScreenState();
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color.fromARGB(255, 218, 210, 210),
      ),
      body: Center(
        child: Text('This is the history page.'),
      ),
    );
  }
}

class _FoodReceiverScreenState extends State<FoodReceiverScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _userName = '';
  List<Meal> _meals = [];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchMealsStream();
  }

  Future<void> _fetchUserName() async {
    User? currentUser = _firebaseAuth.currentUser;

    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('users').doc(currentUser!.uid).get();

      if (snapshot.exists) {
        setState(() {
          _userName = snapshot['name'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
  }

  Stream<List<Meal>> _fetchMealsStream() {
    final String userId = _firebaseAuth.currentUser?.uid ?? '';
    Query<Map<String, dynamic>> mealsQuery =
        FirebaseFirestore.instance.collection('meals');

    mealsQuery = mealsQuery.orderBy('date', descending: true);

    return mealsQuery.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            final String mealStatus = data['status'] ?? '';
            final String mealDonorID = data['donorID'] ?? '';
            final String mealReceiverID = data['receiverID'] ?? '';

            if (mealStatus == 'booked' &&
                mealDonorID != userId &&
                mealReceiverID != userId) {
              return null; // Skip this meal if it's booked and not assigned to the user
            }

            final Timestamp timestamp =
                data['date'] ?? Timestamp.now(); // Get the timestamp

            return Meal(
              mealId: doc.id,
              donorId: data['donorID'] ?? '',
              name: data['name'] ?? '',
              description: data['description'] ?? '',
              location: data['location'] ?? '',
              photo: data['photo'] ?? '',
              status: mealStatus,
              date:
                  timestamp.toDate().toString(), // Convert timestamp to string
            );
          })
          .whereType<Meal>()
          .toList();
    });
  }

  void _navigateToMealDetails(Meal meal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => meal_details.MealDetailsScreen(meal: meal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.grey),
        title: const Text('Find Food Nearby',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => history.HistoryScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.white,
                image: DecorationImage(
                    image: AssetImage('assets/drawerbg.png'),
                    fit: BoxFit.cover),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.black,
                    backgroundImage: AssetImage('assets/AbdullAvatar.png'),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "username: $_userName",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: Text('Chat'),
              leading: Icon(Icons.chat),
              onTap: () {
                // TODO: Implement the chat functionality
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatHistoryScreen()),
                );
              },
            ),
            ListTile(
              title: Text('Sign Out'),
              leading: Icon(Icons.logout),
              onTap: () async {
                await _firebaseAuth.signOut();
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Meal>>(
        stream: _fetchMealsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _meals = snapshot.data!;
            return ListView.builder(
              itemCount: _meals.length,
              itemBuilder: (context, index) {
                final meal = _meals[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: SizedBox(
                      width: 80,
                      height: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          meal.photo,
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object exception,
                              StackTrace? stackTrace) {
                            // Error handling logic goes here
                            // You can display a placeholder image or show an error message
                            return Placeholder(); // Placeholder widget to display when there's an error
                          },
                        ),
                      ),
                    ),
                    title: Text(
                      meal.name,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text(
                          'Location: ${meal.location}',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Description: ${meal.description}',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Status: ${meal.status}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    onTap: () {
                      _navigateToMealDetails(meal);
                    },
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error fetching meals: ${snapshot.error}'),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DishForm()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Color(0xff14c81cb),
      ),
    );
  }
}
