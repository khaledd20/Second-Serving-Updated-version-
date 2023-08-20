import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _verificationId; // Stores the verification ID

  // Send OTP message for phone number verification
  Future<void> sendOtpMessage(String phoneNumber) async {
    final PhoneVerificationCompleted verificationCompleted =
        (PhoneAuthCredential credential) async {
      await _firebaseAuth.signInWithCredential(credential);
    };

    final PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException e) {
      print('Verification failed: ${e.message}');
    };

    final PhoneCodeSent codeSent = (String verificationId, int? resendToken) {
      _verificationId = verificationId; // Store the verification ID
    };

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      print('Code auto retrieval timeout. Verification ID: $verificationId');
    };

    try {
      final phoneNumberFormatted = '+$phoneNumber';
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumberFormatted,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: Duration(seconds: 60),
      );
    } catch (e) {
      print('Failed to send OTP message: ${e.toString()}');
    }
  }

  // Retrieve the verification ID
  String? getVerificationId() {
    return _verificationId;
  }

  // Sign in with email and password
  Future<String?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return 'Logged in successfully!';
    } on FirebaseAuthException catch (e) {
      // Handle authentication exceptions
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Incorrect email or password.';
      } else if (e.code == 'user-disabled') {
        return 'This account has been disabled.';
      } else if (e.code == 'too-many-requests') {
        return 'Too many requests. Try again later.';
      } else {
        return 'An error occurred while trying to log in.';
      }
    }
  }

  // Register with email and password
  Future<String?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      // await userCredential.user!.sendEmailVerification();

      return "Signed up successfully!";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'The account already exists for that email.';
      }
    } catch (e) {
      return "An error occurred while trying to sign up.";
    }
  }

  Future<String> getThisUserName() async {
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      String uid = user.uid;
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      return data?['name'];
    }
    return '';
  }

  Future<String> getUserName(String? uid) async {
    if (uid != null) {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      return data?['name'];
    }
    return '';
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
