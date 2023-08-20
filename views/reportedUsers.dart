import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reportDetailsScreen.dart';

class ReportedUser {
  final String donorId;
  final String email;
  final String name;
  final String phone;

  ReportedUser({
    required this.donorId,
    required this.email,
    required this.name,
    required this.phone,
  });
}

class ReportedUsersScreen extends StatefulWidget {
  @override
  _ReportedUsersScreenState createState() => _ReportedUsersScreenState();
}

class _ReportedUsersScreenState extends State<ReportedUsersScreen> {
  List<ReportedUser> _reportedUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchReportedUsers();
  }

  Future<void> _fetchReportedUsers() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('reports').get();

      final List<ReportedUser> users =
          await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final donorId = data['donorID'] ?? '';

        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(donorId)
            .get();

        final userData = userSnapshot.data();
        final email = userData?['email'] ?? '';
        final name = userData?['name'] ?? '';
        final phone = userData?['phone'] ?? '';

        print(
            'Fetched user: donorId=$donorId, name=$name, email=$email, phone=$phone');

        return ReportedUser(
          donorId: donorId,
          email: email,
          name: name,
          phone: phone,
        );
      }).toList());

      setState(() {
        _reportedUsers = users;
      });
    } catch (e) {
      print('Error fetching reported users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 100,
        leading: TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Sign Out', style: TextStyle(color: Colors.red))),
        title: Text('Reported Users', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: _reportedUsers.length,
        itemBuilder: (context, index) {
          final user = _reportedUsers[index];
          return ListTile(
            title: Text(user.name,
                style:
                    TextStyle(color: Colors.black)), // Display the user's name
            subtitle: Text(user.email,
                style:
                    TextStyle(color: Colors.black)), // Display the user's email
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReportDetailsScreen(donorId: user.donorId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
