import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secondserving/views/register_screen.dart';
import 'package:secondserving/services/firebase_auth_service.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:secondserving/views/share_meal_screen.dart';
import 'food_shared_screen.dart';
import 'reportedUsers.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final firebaseAuth = FirebaseAuthService();
  bool _isPasswordVisible = false;

  void _login(BuildContext context) async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      bool isAdmin = await _checkAdminEmail(username);
      if (isAdmin) {
        String? result = await firebaseAuth.signInWithEmailAndPassword(username, password);
        if (result == 'Logged in successfully!') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReportedUsersScreen()),
          );
        } else {
          final snackBar = SnackBar(content: Text(result!));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } else {
        final snackBar = SnackBar(content: Text('You are not an administrator.'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } else {
      final snackBar = SnackBar(content: Text('Please enter username and password'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<bool> _checkAdminEmail(String email) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('admin').where('email', isEqualTo: email).get();

    return snapshot.docs.isNotEmpty;
  }

  void _navigateToRegisterScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterScreen()),
    );
  }

  void _forgotPassword(BuildContext context) async {
    String username = _usernameController.text;
    if (username.isNotEmpty) {
      FirebaseAuth.instance
          .sendPasswordResetEmail(email: username)
          .then((value) {
        final snackBar = SnackBar(
          content: Text('Password reset email sent. Please check your email inbox.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }).catchError((error) {
        final snackBar = SnackBar(content: Text(error.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    } else {
      final snackBar = SnackBar(
        content: Text('Please enter your email address to reset password'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Administrator Login',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _usernameController,
                style: TextStyle(fontSize: 18.0, color: Colors.green),
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person, color: Colors.green),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: TextStyle(fontSize: 18.0, color: Colors.green),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock, color: Colors.green),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => _login(context),
                child: Text(
                  'Login',
                  style: TextStyle(fontSize: 18.0, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  primary: Colors.green,
                ),
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () => _navigateToRegisterScreen(context),
                child: Text(
                  'Register',
                  style: TextStyle(fontSize: 18.0, color: Colors.green),
                ),
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () => _forgotPassword(context),
                child: Text(
                  'Forgot Password',
                  style: TextStyle(fontSize: 18.0, color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
