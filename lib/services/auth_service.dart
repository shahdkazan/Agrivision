
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _verificationId;
  int? _resendToken;

  // Send OTP
  Future<void> sendOTP(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,

      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        print("ERROR: ${e.code}");
      },

      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        print("CODE SENT: $verificationId"); // should appear in console
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }
  // Verify OTP
  Future<User?> verifyOTP(String smsCode) async {
    try {
      if (_verificationId == null) {
        throw Exception("Verification ID not received yet");
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      User? user = userCredential.user;

      if (user != null) {
        await _saveUserToFirestore(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("VERIFY OTP FAILED: ${e.code} - ${e.message}");
      throw Exception("Invalid OTP or verification failed");
    }
  }

  // Resend OTP
  Future<void> resendOTP(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,

      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        print("RESEND OTP FAILED: ${e.code} - ${e.message}");
        throw Exception(e.message);
      },

      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        print("OTP RESENT");
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // Save user to Firestore
  Future<void> _saveUserToFirestore(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        "userId": user.uid,
        "phoneNumber": user.phoneNumber,
        "role": "Farmer",
        "authProvider": "OTP",
        "name": "",
        "email": "",
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("USER SAVED TO FIRESTORE");
    } catch (e) {
      print("FIRESTORE SAVE FAILED: $e");
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }


  // Login and return user role
  Future<String?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // Get user data from Firestore
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        return userDoc['role']; // return role
      } else {
        return null;
      }
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current user role
  Future<String?> getCurrentUserRole() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    DocumentSnapshot userDoc =
    await _firestore.collection('users').doc(user.uid).get();

    return userDoc['role'];
  }
}
