//main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:secondserving/views/login_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyCHY9o8tJyXwlRwRWciDTDuP0vMktvsD1M",
        appId: "1:566371582218:web:d583fb46a9874aeb967af3",
        messagingSenderId: "566371582218",
        projectId: "secondserving-ef1f1"),
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
      builder: EasyLoading.init(),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
      },
    ),
  );
}
