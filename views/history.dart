import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookedMeal {
  final String mealId;
  final String name;
  final String description;
  final String location;
  final String photo;

  BookedMeal({
    required this.mealId,
    required this.name,
    required this.description,
    required this.location,
    required this.photo,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<BookedMeal> _bookedMeals = [];

  @override
  void initState() {
    super.initState();
    _fetchBookedMeals();
  }

  Future<void> _fetchBookedMeals() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('meals')
              .where('status', isEqualTo: 'booked')
              .where('receiverID', isEqualTo: userId)
              .get();

      final List<BookedMeal> meals = snapshot.docs.map((doc) {
        final data = doc.data();
        return BookedMeal(
          mealId: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          location: data['location'] ?? '',
          photo: data['photo'] ?? '',
        );
      }).toList();

      setState(() {
        _bookedMeals = meals;
      });
    } catch (e) {
      print('Error fetching booked meals: $e');
    }
  }

  void _updateMealStatus(String mealId) async {
    try {
      await FirebaseFirestore.instance.collection('meals').doc(mealId).update({
        'status': 'not booked',
        'receiverID': '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meal status updated successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

      // Refresh the list of booked meals
      _fetchBookedMeals();
    } catch (e) {
      print('Error updating meal status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update meal status. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        title: const Text('History', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: _bookedMeals.length,
        itemBuilder: (context, index) {
          final meal = _bookedMeals[index];
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
                  ),
                ),
              ),
              title: Text(
                meal.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  _updateMealStatus(meal.mealId);
                },
                child: Text('unbook'),
              ),
            ),
          );
        },
      ),
    );
  }
}
