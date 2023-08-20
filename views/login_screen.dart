import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
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
  EasyLoading.show(status: 'Authenticating...');
  
  if (username.isNotEmpty && password.isNotEmpty) {
    String? result = await firebaseAuth.signInWithEmailAndPassword(username, password);

    if (result == 'Logged in successfully!') {
      EasyLoading.dismiss();

      // Check if the logged-in user's email is in the admin collection
      bool isAdmin = await isAdminEmail(username);
      
      if (isAdmin) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReportedUsersScreen()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FoodReceiverScreen()),
        );
      }
    } else {
      EasyLoading.dismiss();
      final snackBar = SnackBar(content: Text(result!));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  } else {
    EasyLoading.dismiss();
    final snackBar = SnackBar(content: Text('Please enter username and password'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

Future<bool> isAdminEmail(String email) async {
  try {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('admin')
        .where('email', isEqualTo: email)
        .get();

    return snapshot.size > 0; // If the snapshot has documents, the email is an admin email
  } catch (e) {
    print('Error checking admin email: $e');
    return false;
  }
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
          content:
              Text('Password reset email sent. Please check your email inbox.'),
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
      body: SingleChildScrollView(
        child: Container(
          color: Color(0xfafafa),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(1.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // add image
                ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.transparent],
                    ).createShader(Rect.fromLTRB(0, 0, rect.width, 1500));
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/loginbg.png',
                    height: 400,
                    fit: BoxFit.contain,
                  ),
                ),

                TextField(
                  controller: _usernameController,
                  style: TextStyle(fontSize: 18.0, color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person, color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: TextStyle(fontSize: 18.0, color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.black,
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
                  style: ButtonStyle(
                    elevation: MaterialStateProperty.all<double>(
                        4.0), // Shadow elevation
                    minimumSize: MaterialStateProperty.all<Size>(
                        Size(300, 48.0)), // Button width
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.white), // Button background color
                    shadowColor: MaterialStateProperty.all<Color>(
                        Colors.grey), // Shadow color
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                ElevatedButton(
                  onPressed: () => _navigateToRegisterScreen(context),
                  child: Text(
                    'Register',
                    style: TextStyle(fontSize: 18.0, color: Colors.white),
                  ),
                  style: ButtonStyle(
                    elevation: MaterialStateProperty.all<double>(
                        4.0), // Shadow elevation
                    minimumSize: MaterialStateProperty.all<Size>(
                        Size(300, 48.0)), // Button width
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Color(0xff14c81cb)), // Button background color
                    shadowColor: MaterialStateProperty.all<Color>(
                        Colors.grey), // Shadow color
                  ),
                ),

                TextButton(
                  onPressed: () => _forgotPassword(context),
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(fontSize: 18.0, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
